import{s as n}from"./toast.DeilrAYO.js";const t=document.getElementById("copy-link");t?.addEventListener("click",()=>{navigator.clipboard.writeText(window.location.href),n({message:"Link copied!"})});const o=document.getElementById("get-qrcode"),e=document.getElementById("qrcode-container");if(!e)throw new Error("qrcode container not found");o?.addEventListener("click",()=>{e.ariaExpanded==="true"?e.ariaExpanded="false":e.ariaExpanded="true"});
