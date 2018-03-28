function documentAttachmentsFieldsControl(obj) {
    var attachment_rows = document.getElementsByName("attachment_row");
    for(var i = attachment_rows.length - 1; i >= 1; i--) {
        if(attachment_rows[i] && attachment_rows[i].parentElement) {
            attachment_rows[i].parentElement.removeChild(attachment_rows[i]);
        }
    }
    fileFieldCount = 1;
    var i = 0;
    try {
        var files = obj.files;
        var len = files.length;
        if (len > 0) {
          var active_row = document.getElementById("attachments[1][file_name]");
          active_row.textContent = files[0].name;
          for (i = 1; i < len && i < 10; i++) {
            addFileField();
            active_row = document.getElementById("attachments[" + (i+1) + "][file_name]");
            active_row.textContent = files[i].name;
          }
        }
    }
    catch (e) {
        
    }
}