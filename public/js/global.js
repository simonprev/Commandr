$(document).ready(function() {
$("#login").bind('submit',verifierForm);
var formValide="false";

function verifierForm(e){
  
    $.ajax({
    type: "POST",
    asynch: false,  
    url: "/login",
    dataType: "text",
    data: "username="+$("#username").val()+"&password="+$("#password").val(),
    success: function(msg){
      if(msg=="true"){
      redirection(msg);
      }else{
      $("#erreur").html("Les informations de connexion sont invalides");
      }
    }
    });
    e.preventDefault();
};

});

function redirection(msg){
window.location.replace("/");
}


