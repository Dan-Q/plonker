"use strict";
(function(){
  const DICTIONARIES = [
    ['dodgy','daft','naff','sad','shite','skiving','cheeky','nosey','dozy','whinging','stinky','rubbish','barmy','duff','grubby','dim'],
    ['ugly','gormless','bloody','chavvy','shitting','godforsaken','effing','poor','stupid','skanky','fucking','pikey','plastered','nesh','wimpy','buggered'],
    ['muppet','git','moron','pillock','twit','knob','wazzock','berk','ninny','blighter','sod','bellend','wanker','arsehole','divvy','nutter'],
  ];

  function pad(number, padWidth, paddingChar) {
    paddingChar = paddingChar || '0';
    number = number + '';
    return number.length >= padWidth ? number : new Array(padWidth - number.length + 1).join(paddingChar) + number;
  }

  function encode(binary_string){
    return pad(binary_string, 12).match(/.{4}/g).map(function(b, i){ return DICTIONARIES[i % 3][parseInt(b, 2)]; }).join('-');
  }

  function updateUrl(){
    let name = $('#name').val().toLowerCase().replace(/['\. ]+/, '.').replace(/[^a-z0-9\-\.]+/, '').replace(/^\.+/, '').replace(/\.+$/, '');
    let pronoun = parseInt($('#pronoun').val());
    let loc = parseInt($('#locality').val());
    let domain = 'isaplonker.uk';
    let address = (name.length > 0 ? `${name}.${domain}` : '');
    if(name.length > 0 && (pronoun != 0 || loc != 268) && $('#setup').hasClass('advanced')){
      // encode the pronoun (2 bits) and locality (10 bits) as three 4-bit (i.e. Base16) numbers, represented by 16 strings
      let suffix = encode(pad(pronoun.toString(2), 2) + pad(loc.toString(2), 10));
      $('#result').attr('href', `http://${address}/${suffix}`).text(`${address}/${suffix}`);
    } else {
      $('#result').attr('href', `http://${address}`).text(address);
    }
  }

  jQuery(function($){
    $('body').addClass('js');

    $('#advanced-button').on('click', function(){
      $(this).closest('#setup').toggleClass('advanced');
      return false;
    });

    $('input, select').on('change keyup click', updateUrl);
    updateUrl();

    $('input:first').focus();
  });  
})();
