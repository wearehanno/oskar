$(document).ready(function() {
  Tipped.create('.tipped');
  $('.timeago').timeago();


  $('.send-msg').on('click', function(e) {
    $(this).hide();
    $(this).parent().find('.send-msg-form').show();
    return false;
  });

  $('.send-msg-form').on('submit', function() {

    // data
    var userId = $(this).find('.send-msg-form-userid').val();
    var message = $(this).find('.send-msg-form-message').val();

    // ajax request
    $.ajax({
      url: "/message/" + userId,
      type: 'POST',
      data: JSON.stringify({ message: message }),
      contentType: 'application/json; charset=utf-8',
      dataType: 'json'
    })
    .done(function( msg ) {
      alert( "Data Saved: " + msg );
    });

    // show success message
    $(this).hide();
    $(this).parent().append('<p class="text-success">Your message has been sent!</p>');

    return false;
  });

});