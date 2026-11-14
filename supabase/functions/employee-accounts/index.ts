// employee-accounts — action "delete_employee" added 2026-11-13 (needs
// supabase/migrations/20261113110000_delete_employee.sql applied first).
// Before that: deployed version 1 plus optional `role` and `phone` on
// create_employee (see supabase/migrations/20261102090100_account_role_and_phone.sql).
// Only employeeInput() changed. Deploy with:
//   supabase functions deploy employee-accounts --no-verify-jwt
// (verify_jwt stays off: the handler verifies the caller against Auth itself.)
//
// No dependencies. Secrets remain in the server transport; handler never logs request bodies.
export class AccountError extends Error {
  constructor(status, code, message) { super(message); this.status=status; this.code=code; }
}
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const fail = (message) => { throw new AccountError(400,'invalid_input',message); };
export function validatePassword(password) {
  if (typeof password!=='string') fail('Password is required');
  const bytes = new TextEncoder().encode(password).length;
  if ([...password].length<12 || bytes>72 || !password.trim()) fail('Password must be at least 12 characters and at most 72 UTF-8 bytes');
}

export function employeeInput(body) {
  const required = ['request_id','full_name','username','email','password','employee_code','schedule_id'];
  // role and phone are optional, so older app versions keep working.
  const allowed = ['action',...required,'role','phone'];
  if (Object.keys(body).some(key => !allowed.includes(key))) fail('Unexpected employee field');
  for (const key of required) {
    if (typeof body[key]!=='string') fail('All employee fields and request_id are required');
  }
  for (const key of ['role','phone']) {
    if (body[key]!==undefined && body[key]!==null && typeof body[key]!=='string') fail('Invalid '+key);
  }
  const role = (body.role ?? 'employee').trim() || 'employee';
  if (role!=='employee' && role!=='admin') fail('Role must be employee or admin');
  const phone = (body.phone ?? '').trim() || null;
  if (phone!==null && !/^\+[1-9][0-9]{7,14}$/.test(phone)) fail('Phone must be in international format, for example +201012345678');
  const details = {
    full_name: body.full_name.trim(), username: body.username.trim().toLowerCase(),
    email: body.email.trim().toLowerCase(), employee_code: body.employee_code.trim().toUpperCase(),
    schedule_id: body.schedule_id, role, phone,
  };
  if (!uuid.test(body.request_id) || !uuid.test(details.schedule_id)) fail('Valid request and schedule UUIDs are required');
  if (!details.full_name || details.full_name.length>200) fail('Full name must contain 1–200 characters');
  if (!/^[a-z0-9][a-z0-9._-]{2,63}$/.test(details.username)) fail('Username must contain 3–64 permitted characters');
  if (!/^[A-Z0-9][A-Z0-9_-]{1,49}$/.test(details.employee_code)) fail('Employee code must contain 2–50 permitted characters');
  if (details.email.length>254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(details.email)) fail('A valid email is required');
  // Auth stores bcrypt hashes: avoid silent truncation at its 72-byte input boundary.
  validatePassword(body.password);
  return { requestId: body.request_id, details, password: body.password };
}

export function createAccountHandler({authenticate, rpc, createUser, sendReset, updatePassword, deleteUser, allowedOrigin=''}) {
  return async function handler(request) {
    const origin = request.headers.get('origin');
    const headers = {'Content-Type':'application/json','Cache-Control':'no-store','Vary':'Origin'};
    if (origin && origin===allowedOrigin) Object.assign(headers,{
      'Access-Control-Allow-Origin':origin,
      'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info',
      'Access-Control-Allow-Methods':'POST, OPTIONS',
    });
    const respond = (status,data) => new Response(JSON.stringify(data),{status,headers});
    try {
      if (origin && origin!==allowedOrigin) throw new AccountError(403,'origin_denied','Origin is not permitted');
      if (request.method==='OPTIONS') return new Response(null,{status:204,headers});
      if (request.method!=='POST') return respond(405,{error:'method_not_allowed'});
      const match = /^Bearer (\S+)$/i.exec(request.headers.get('authorization')??'');
      if (!match) throw new AccountError(401,'unauthorized','A user access token is required');
      // Verification is against Auth, not an unverified JWT decode or an actor ID from JSON.
      const actor = await authenticate(match[1]);
      if (!actor?.id) throw new AccountError(401,'unauthorized','Invalid user session');
      const text = await request.text();
      if (new TextEncoder().encode(text).length>8192) throw new AccountError(413,'payload_too_large','Request is too large');
      let body;
      try { body=JSON.parse(text); } catch { fail('Invalid JSON'); }
      if (!body || typeof body!=='object' || Array.isArray(body)) fail('A JSON object is required');
      if (body.action==='change_password') {
        if (Object.keys(body).some(k=>!['action','password','current_password','nonce'].includes(k))) fail('Unexpected password field');
        validatePassword(body.password);
        for (const key of ['current_password','nonce']) {
          if (body[key]!==undefined && typeof body[key]!=='string') fail('Invalid password verification field');
        }
        if (body.current_password!==undefined && body.password===body.current_password) fail('Choose a different new password');
        await rpc('backend_password_context',{p_actor:actor.id}); // Allows active first-login/recovery users.
        const attributes={password:body.password};
        if(body.current_password!==undefined) attributes.current_password=body.current_password;
        if(body.nonce!==undefined) attributes.nonce=body.nonce;
        // Native Auth applies password strength, reuse and any reauthentication/nonce checks.
        await updatePassword(match[1],attributes);
        try { await rpc('backend_complete_password_change',{p_actor:actor.id}); }
        catch {
          // Auth may have accepted the new password; keep the business gate closed.
          throw new AccountError(503,'password_completion_pending','Password may have changed. Sign in with it and submit another different password to complete setup');
        }
        return respond(200,{message:'Password changed'});
      }
      if (body.action==='create_employee') {
        const {requestId,details,password} = employeeInput(body);
        const args = {p_actor:actor.id,p_request_id:requestId,p_details:details};
        const check = await rpc('backend_validate_employee',args);
        if (check.existing_id) return respond(200,{id:check.existing_id,replayed:true});
        let creationError;
        try {
          await createUser({email:details.email,password,email_confirm:true,
            app_metadata:{attendance_account:{...details,request_id:requestId,created_by:actor.id}},
          });
        } catch (error) { creationError=error; }
        // Always reconcile after an ambiguous Auth response. The insert trigger owns the
        // transaction: the complete account exists or none of the new rows were committed.
        // A lost response never causes deletion of a successfully created employee.
        let final;
        try { final=await rpc('backend_validate_employee',args); }
        catch (error) {
          if (creationError && error.code==='23505') throw error;
          throw new AccountError(503,'outcome_unknown','Retry with the SAME request_id and account details');
        }
        if (final.existing_id) return respond(201,{id:final.existing_id,replayed:false,must_change_password:true});
        if (creationError) throw creationError;
        throw new AccountError(503,'outcome_unknown','Retry with the SAME request_id and account details');
      }
      if (body.action==='send_password_reset') {
        if (Object.keys(body).some(k=>!['action','employee_id'].includes(k)) || !uuid.test(body.employee_id??'')) fail('A valid employee_id is required');
        const email = await rpc('backend_reset_email',{p_actor:actor.id,p_employee_id:body.employee_id});
        await sendReset(email); // Fixed server-configured redirect, never a caller-supplied URL.
        return respond(202,{message:'If delivery is available, password reset instructions will be emailed'});
      }
      if (body.action==='delete_employee') {
        if (Object.keys(body).some(k=>!['action','employee_id'].includes(k)) || !uuid.test(body.employee_id??'')) fail('A valid employee_id is required');
        const target = body.employee_id.toLowerCase();
        if (target===String(actor.id).toLowerCase()) throw new AccountError(403,'forbidden','You cannot delete your own account');
        // The database decides: the caller must be an active admin and the target an
        // employee (never an admin, so the last administrator is out of reach). In one
        // transaction it ends the sessions, removes phones, notifications and
        // permissions, and either deletes the profile ("hard") or, when attendance,
        // requests or audit history refer to it, locks it ("anonymized").
        const result = await rpc('backend_delete_employee',{p_actor:actor.id,p_employee_id:target});
        const mode = result?.mode;
        if (mode!=='hard' && mode!=='anonymized' && mode!=='gone') throw new AccountError(503,'account_service_unavailable','Retry safely');
        // Then the login itself. A kept record still points at its Auth user, so that
        // user is soft-deleted: email and password are destroyed for good and the row
        // stays only as an anchor. Repeating the request finishes a half-done deletion.
        let removed;
        try { removed = await deleteUser(target, mode==='anonymized'); }
        catch { throw new AccountError(503,'auth_delete_pending','The account can no longer be used. Repeat the request to finish removing its login'); }
        if (mode==='gone' && !removed) return respond(404,{error:'not_found',message:'Employee not found'});
        return respond(200,{deleted:true,mode:mode==='gone'?'hard':mode});
      }
      fail('Unsupported action');
    } catch (error) {
      if (error.code==='42501') return respond(403,{error:'forbidden',message:'Active authorized admin with completed password change required'});
      if (error.code==='23505') return respond(409,{error:'account_conflict',message:'Username, employee code, email or request ID already exists'});
      if (error.code==='22023' || error.code==='22P02' || error.code==='23514') return respond(400,{error:'invalid_input',message:'Invalid employee details or schedule'});
      if (error instanceof AccountError) return respond(error.status,{error:error.code,message:error.message});
      // Do not forward database internals, request bodies, passwords, keys or Auth responses.
      return respond(503,{error:'account_service_unavailable',message:'Retry safely with the same request_id'});
    }
  };
}

export function supabaseTransport({url,publicKey,serviceKey,resetRedirect,fetchImpl=fetch}) {
  const base=url.replace(/\/$/,'');
  async function request(path,{token=serviceKey,key=serviceKey,method='POST',body}={}) {
    const response=await fetchImpl(base+path,{method,headers:{
      apikey:key,Authorization:'Bearer '+token,'Content-Type':'application/json',
    },body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
    let data;
    try { data=await response.json(); } catch { data=null; }
    if (!response.ok) {
      const code=data?.code??data?.error_code??'upstream_error';
      // Only controlled messages leave the server.
      const status = response.status===429 ? 429 : response.status>=500 ? 503 : 400;
      const error = new AccountError(status,code,response.status===429?'Try again later':'Account operation was rejected');
      error.upstreamStatus = response.status;
      throw error;
    }
    return data;
  }
  return {
    authenticate: async token => {
      try { return await request('/auth/v1/user',{method:'GET',token,key:publicKey}); }
      catch { throw new AccountError(401,'unauthorized','Invalid or expired session'); }
    },
    rpc: (name,args) => request('/rest/v1/rpc/'+name,{body:args}),
    createUser: body => request('/auth/v1/admin/users',{body}),
    // true when a user was removed, false when Auth has no such user (already gone).
    deleteUser: async (id,soft) => {
      try { await request('/auth/v1/admin/users/'+id,{method:'DELETE',body:{should_soft_delete:soft}}); return true; }
      catch (error) {
        if (error.upstreamStatus===404 || error.code==='user_not_found') return false;
        throw error;
      }
    },
    updatePassword: (token,attributes) => request('/auth/v1/user',{
      method:'PUT',token,key:publicKey,body:attributes,
    }),
    sendReset: email => {
      if (!resetRedirect) throw new AccountError(503,'reset_not_configured','Password reset redirect is not configured');
      return request('/auth/v1/recover?redirect_to='+encodeURIComponent(resetRedirect),{
        key:publicKey,token:publicKey,body:{email},
      });
    },
  };
}


// These are Edge secrets. Nothing in this file is a Flutter configuration value.
function required(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error('Missing required server configuration: ' + name);
  return value;
}
const transport = supabaseTransport({
  url: required('SUPABASE_URL'),
  publicKey: required('SUPABASE_ANON_KEY'),
  serviceKey: required('SUPABASE_SERVICE_ROLE_KEY'),
  resetRedirect: Deno.env.get('PASSWORD_RESET_REDIRECT_URL') ?? '',
});
Deno.serve(createAccountHandler({
  ...transport,
  allowedOrigin: Deno.env.get('ALLOWED_WEB_ORIGIN') ?? '',
}));
