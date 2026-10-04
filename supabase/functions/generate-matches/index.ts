import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
serve(async req=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const {request_id}=await req.json(); if(!request_id) throw new Error("request_id required");
  const {data,error}=await supabase.rpc("generate_matches",{p_request_id:request_id}); if(error) throw error;
  return new Response(JSON.stringify({ok:true,matches:data||[]}),{headers:{...cors,"Content-Type":"application/json"}});
 }catch(e){return new Response(JSON.stringify({ok:false,error:String(e.message||e)}),{status:400,headers:{...cors,"Content-Type":"application/json"}})}
});