import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

serve(async req=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  try{
    const b=await req.json();
    const required=["parent_name","whatsapp","student_level","subject"];
    for(const k of required) if(!String(b[k]||"").trim()) throw new Error("Missing required field: "+k);
    if(b.consent!==true) throw new Error("Consent is required.");
    const {data,error}=await supabase.from("parent_requests").insert({...b,status:"new"}).select("id").single();
    if(error) throw error;
    return new Response(JSON.stringify({ok:true,id:data.id}),{headers:{...cors,"Content-Type":"application/json"}});
  }catch(e){return new Response(JSON.stringify({ok:false,error:String(e.message||e)}),{status:400,headers:{...cors,"Content-Type":"application/json"}})}
});