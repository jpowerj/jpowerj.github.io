$(document).ready(function() {
  // hide diag1
  $("#diag1").find("code").parent().attr("id","diag1code")
  $("#diag2").find("code").parent().attr("id","diag2code")
  $("#diag1code").addClass("collapse")
  $("#diag2code").addClass("collapse")
  //$("#diag1code").css("display","none")
  // the button
  var b1 = $('<button type="button" class="btn btn-default btn-xs code-folding-btn pull-right"><span>Code</span></button>');
  b1.attr('data-toggle', 'collapse')
        .attr('data-target', '#diag1code')
        .attr('aria-expanded', "false")
        .attr('aria-controls', "diag1code");
  var b2 = $('<button type="button" class="btn btn-default btn-xs code-folding-btn pull-right"><span>Code</span></button>');
  b2.attr('data-toggle', 'collapse')
        .attr('data-target', '#diag2code')
        .attr('aria-expanded', "false")
        .attr('aria-controls', "diag2code");

  // function to toggle the visibility
  b1.click(function(){
    $(this).text(function(i,old){
        return old=='Code' ?  'Hide' : 'Code';
    });
  });
  b2.click(function(){
    $(this).text(function(i,old){
        return old=='Code' ?  'Hide' : 'Code';
    });
  });

  $("#diag1").prepend(b1);
  $("#diag2").prepend(b2);
});