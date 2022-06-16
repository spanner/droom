function DocumentEditorForm(e) {
  e.preventDefault();

  var form = e.target;
  var formData = new FormData(e.target);
  var replacedId = $('#document_id').val();

  $.ajax({
    url: form.action,
    type: 'PUT',
    success: function(data) {
      var element = $(`#document_${replacedId}`);
      var filename = data.file_file_name;
      var shortname = filename;

      if (filename.length > 10) {
        shortname = filename.substring(0, 25) + "...";
      }

      element.find('a.document').attr('herf', `/folders/${data.folder_id}/documents/${data.id}`);
      element.find('span.shortened').attr('title', data.file_file_name).text(shortname);

      $('.popup .closer').click();

      element.css('background-color', '#acebb1')
      setTimeout(function(){
          element.css('background-color', '');
       }, 1000);
    },
    data: formData,
    cache: false,
    contentType: false,
    processData: false
  }).fail(function (jqXHR, textStatus, error) {
    $('p.error').text(jqXHR.responseText)
  });
}
