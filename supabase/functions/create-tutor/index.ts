import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
serve(async req=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const b=await req.json(); if(!b.full_name||!b.whatsapp||!b.subjects||!b.levels) throw new Error("Please complete the required tutor fields.");
  const {data,error}=await supabase.from("tutors").insert({...b,status:"pending"}).select("id").single(); if(error) throw error;
  return new Response(JSON.stringify({ok:true,id:data.id}),{headers:{...cors,"Content-Type":"application/json"}});
 }catch(e){return new Response(JSON.stringify({ok:false,error:String(e.message||e)}),{status:400,headers:{...cors,"Content-Type":"application/json"}})}
});