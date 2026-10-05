import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS","Content-Type":"application/json"};
Deno.serve(async req=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const authHeader=req.headers.get("Authorization");
  if(!authHeader) return new Response(JSON.stringify({ok:false,error:"Authentication required"}),{status:401,headers:cors});
  const url=Deno.env.get("SUPABASE_URL")!;
  const key=Deno.env.get("SUPABASE_ANON_KEY")||Deno.env.get("SUPABASE_PUBLISHABLE_KEY")!;
  const db=createClient(url,key,{global:{headers:{Authorization:authHeader}}});
  const {data:{user},error:userError}=await db.auth.getUser();
  if(userError||!user) return new Response(JSON.stringify({ok:false,error:"Invalid session"}),{status:401,headers:cors});
  const {data:isAdmin,error:adminError}=await db.rpc("is_admin");
  if(adminError||!isAdmin) return new Response(JSON.stringify({ok:false,error:"Admin access required"}),{status:403,headers:cors});
  const body=await req.json().catch(()=>null),request_id=body?.request_id;
  if(!request_id) return new Response(JSON.stringify({ok:false,error:"request_id required"}),{status:400,headers:cors});
  const {data,error}=await db.rpc("generate_matches",{p_request_id:request_id});
  if(error) throw error;
  return new Response(JSON.stringify({ok:true,matches:data||[]}),{headers:cors});
 }catch(e){console.error("generate-matches error",e);return new Response(JSON.stringify({ok:false,error:"Match Engine failed. Please retry or check Admin logs."}),{status:500,headers:cors})}
});