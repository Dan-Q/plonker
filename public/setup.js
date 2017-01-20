"use strict";
(function(){
  function updateUrl(){
    var name = $('#name').val();
    name = name.toLowerCase().replace(/['\. ]+/, '.').replace(/[^a-z0-9\-\.]+/, '').replace(/^\.+/, '').replace(/\.+$/, '');
    var domain = 'isaplonker.uk';
    var address = (name.length > 0 ? `${name}.${domain}` : '');
    $('#result').attr('href', `http://${address}`).text(address);
  }

  jQuery(function($){
    $('body').addClass('js');

    $('#advanced-button').on('click', function(){
      $(this).closest('#setup').toggleClass('advanced');
      return false;
    });

    $('#name').on('change keyup', updateUrl);
    updateUrl();

    $('input:first').focus();
  });  
})();
