import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS","Content-Type":"application/json"};
Deno.serve(async req=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 if(req.method!=="POST") return new Response(JSON.stringify({ok:false,error:"POST only"}),{status:405,headers:cors});
 const body=await req.json().catch(()=>null),token=body?.token,requestedStatus=body?.status;
 if(!token||!["accepted","declined"].includes(requestedStatus)) return new Response(JSON.stringify({ok:false,error:"Invalid response"}),{status:400,headers:cors});
 const db=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
 const {data:match,error:findError}=await db.from("matches").select("id,request_id,tutor_id,status").eq("response_token",token).single();
 if(findError||!match) return new Response(JSON.stringify({ok:false,error:"Link expired or invalid"}),{status:404,headers:cors});
 if(["accepted","declined"].includes(match.status)) return new Response(JSON.stringify({ok:true,status:match.status,alreadyRecorded:true}),{headers:cors});
 const {error:updateError}=await db.from("matches").update({status:requestedStatus,response_note:requestedStatus==="accepted"?"Tutor accepted via SmartMatch response page":"Tutor declined via SmartMatch response page"}).eq("id",match.id);
 if(updateError) return new Response(JSON.stringify({ok:false,error:updateError.message}),{status:500,headers:cors});
 if(requestedStatus==="accepted"){
  const {error:requestError}=await db.from("parent_requests").update({status:"trial"}).eq("id",match.request_id).not("status","in","(confirmed,closed)");
  if(requestError) return new Response(JSON.stringify({ok:false,error:requestError.message}),{status:500,headers:cors});
 }
 await db.from("admin_activity_logs").insert({admin_user_id:null,action:requestedStatus==="accepted"?"Tutor accepted match":"Tutor declined match",entity_type:"match",entity_id:match.id,details:{source:"tutor-response",tutor_id:match.tutor_id,request_id:match.request_id,status:requestedStatus}});
 return new Response(JSON.stringify({ok:true,status:requestedStatus,alreadyRecorded:false}),{headers:cors});
});