$(function() {
  $('#notice').hide()
  $('#notice').slideDown();

  if($('#notice').length != 0){
    $('#notice').delay(5000).slideUp();
  }
});

$.extend({
  getUrlVars: function(){
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
      hash = hashes[i].split('=');
      vars.push(hash[0]);
      vars[hash[0]] = hash[1];
    }
    return vars;
  },
  getUrlVar: function(name){
    return $.getUrlVars()[name];
  }
});

$(function() {
  $(".list_stat_post").each(function(){
    var $this=$(this);
    $this.hide();
    });

  $('.publications li').live({
    mouseover: function() {
    var $this= $(this);
    $this.find(".list_stat_post").stop().css("display","inline-block").fadeTo(200, 1);
    },
    mouseout: function() {
    var $this= $(this);
    $this.find(".list_stat_post").stop().fadeTo(200, 0);
    }
  });


});
$(function() {

  $("#plus").each(function() {
    var $this = $(this);

    $this.ajaxStart(function(){
      $this.html("<img src=\"/images/ajax-loader.gif\" alt=\"loading\">");
    });

    $this.ajaxStop(function(){
      $this.html("Plus");
    });

    $this.click(function(){
      var no_page=($this.attr("href")).substring(1);
      var tri =$.getUrlVar('tri');

      $.ajax({
        type : "GET",
        url : $this.parent().data("path"),
        data : { page : no_page, tri : tri },
        dataType : 'json',
        success : function(data) {
          if (data.pagination != no_page) {
            var nextPage=(parseFloat(no_page)+1).toString();
            $this.attr("href","#"+nextPage);
          } else {
            $this.parent().remove();
          }
          if ($(".publications").length!=0){
            $(".publications").append(data.html);
              $(".list_stat_post").each(function(){
                var $this=$(this);
                $this.hide();
              });
          } else {
            $(".auteur").append(data.html);
          }
        }
      });
      return false;
    })
  });

});
