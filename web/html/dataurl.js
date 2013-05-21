
/* prep everything once page is loaded */
function Init ()
{
    document.getElementById('cssurl').addEventListener("keyup", URLFieldKeyHandler, true);
    document.getElementById('fileinput').addEventListener('change', HandleFileSelect, false);
    
    if (Boolean(ReadCookie('compress_css')) == 'true') 
    {
        $('#compress_css').prop('checked', true);
    }
    
    $('#cssurl').val(ReadCookie('css_url'));
    
    if (HasFileAPIs()) 
    {
        var uploadPlace =  document.getElementById('droparea');
        uploadPlace.addEventListener("dragover", function(event) {
            event.stopPropagation(); 
            event.preventDefault();
        }, true);
        uploadPlace.addEventListener("drop", handleDrop, false);
        uploadPlace = document.getElementById('dataurldisplay');
        uploadPlace.addEventListener("dragover", function(event) {
            event.stopPropagation(); 
            event.preventDefault();
        }, true);
        uploadPlace.addEventListener("drop", handleDrop, false);
        
        $("#droparea").html('<br><br>Drag file here');
    }
    else {
        $("#droparea").html('<br><br>Select file');
    }
    if (window.location.hash) {
        ShowPage(window.location.hash.substring(1)); 
    } else {
        ShowPage('about');
    }
}

/* tells us whether browser has File API support*/
function HasFileAPIs ()
{
    return (window.File && window.FileReader && window.FileList && window.Blob);
}

/* tab navigation select function*/
function ShowPage (a_element)
{
    /* show relevant block for the page*/
    $(".page").css("display", "none");
    $("#body_" + a_element).css("display","block");
    window.location.hash = '#' + a_element;
    
    /* Remove selected style from all, add to selected item*/
    $(".litem").attr("id","");
    $('li[name=' + a_element + ']').attr("id", 'selected');
}

/* file selection handler for data url maker*/
function HandleFileSelect(evt) 
{
    if (!HasFileAPIs()) 
    {
        /* without File APIs, we submit form in background into iframe
           and read the resulting JSON in the onload handler*/
        document.getElementById('postframe').onload = DataURLLoaded;
        $("#upload-form").submit();
        return;
    }
    /* with the File APIs, we can just get the file object
       and start working with it, no server-side processing required */
    ReadDataFile(evt.target.files[0]);
}

/* handler function when Data URL Maker form submission has finished
   in the hidden iframe.  Result should be JSON text containing the 
   DataURL and file info */
function DataURLLoaded ()
{
    var dict, contents = $("#postframe").contents().text();
    if (contents == '') { return; }
    
    /* eval the JSON */
    dict = eval('(' + contents + ')');
    
    if ('error' in dict) 
    {  
        $("#droparea").html(dict['error']);
        return;
    }
    
    /* fill in the fields */
    $("#dataurltextarea").html(dict['dataurl']);
    $("#dataurlfilename").html(dict['filename']);
    $("#droparea").css('display', 'none');
    $("#dataurlfilesize").html('Data URL Size: ' + dict['size'] + ' bytes<br>Gzipped URL size: ' + dict['gzipsize'] + ' bytes<br>Original size: ' + dict['origsize'] + ' bytes');
    if (dict['image'])
        $("#dataurlimg").html('<img src="' + dict['dataurl'] + '">')
    else
        $("#dataurlimg").html('Not an image');
    $("#dataurldisplay").css('display', 'block');
}


/* Read through entire data file from File APIs
  and fill fields with values */
function ReadDataFile (file)
{
    var reader = new FileReader();
    
    /* Handler function called once file is loaded.  */
    reader.onload = (function(theFile) {
          return function(e) {
            var suffix = theFile.name.split('.').pop();
            $("#dataurltextarea").html(e.target.result);
            $("#dataurlfilename").html(theFile.name)
            $("#droparea").css('display', 'none');
            $("#dataurlfilesize").html('Data URL Size: ' + e.target.result.length + ' bytes<br>Original size: ' + theFile.size + ' bytes');
            if (/^jpg|png|gif|jpeg$/i.test(suffix))
                $("#dataurlimg").html('<img src="' + e.target.result + '">')
            else
                $("#dataurlimg").html('Not an image');
            $("#dataurldisplay").css('display', 'block');
    };})(file);

    /* Read in the image file as a data URL. */
    reader.readAsDataURL(file);
}

/* Function drop file */
function handleDrop (event)
{
    event.preventDefault();
    event.stopPropagation();
    ReadDataFile(event.dataTransfer.files[0]);
}

function ShowLoader (bool)
{
    if (bool)
    {
        $('#optimizebutton').attr('disabled', 'disabled');
        $("#cssurl").attr('disabled', 'disabled');
        $("#status_message").css('display', 'none');
        $("#css_output_container").css('display', 'none');
        $('#ajaxloader_wrapper').css('display', 'block');
    }
    else
    {
        $('#optimizebutton').removeAttr('disabled');
        $('#cssurl').removeAttr('disabled');
        $('#ajaxloader_wrapper').css('display', 'none');
    }
}

function CompressCSSClicked(elem)
{
    var val = $(elem).prop('checked');
    SetCookie('compress_css=' + val);
}

function OptimizerError(errmsg)
{
    $("#status_message").html('<em>ERROR: ' + errmsg + '</em>');
    $("#status_message").css('display', 'block');
    ShowLoader(0);
}

/* Call server-side application, and display 
   its response in a prettified way */
function OptimizeCSS ()
{
    var unixtime = Math.round((new Date()).getTime() / 1000), 
        lastRequest = 0, 
        cookieStr = ReadCookie('lastRequest'), 
        limit = $('#css_sizelimit').val(), 
        compress = $('input:checkbox[name=compress]:checked').val(),
        optimg = $('input:checkbox[name=optimize_images]:checked').val(),
        href = '/cgi-bin/dataurl.pl?action=optimize&compress=' + compress + '&optimize_images=' + optimg + '&size_limit=' + limit + '&css_file_url=' + $('#cssurl').val();
    
    // save remote URL into cookie
    SetCookie('css_url=' + $('#cssurl').val());
    
    /* Cooldown check.  This is still enforced server-side
       but saves us requests to the server unless the user
       actually bothers to disable cookies to fool us.  */
    if (cookieStr != null) { lastRequest = parseInt(cookieStr); }
    if (lastRequest > unixtime - 5)
    {
        OptimizerError('Cooldown in effect.  Please try again in ' + ((unixtime - 5 - lastRequest) * -1) + ' seconds.');
        return;
    }
    
    ShowLoader(1);
    SetCookie('lastRequest=' + unixtime);
    
    $.get(href, function(data) 
    {        
        if ('error' in data) { OptimizerError(data['error']); return; }
        
        /* Generate ext. resources list */
        var listhtml = '<tr><td width="25"><span>Req.</span></td><td width="40%"><span>Remote URL</span></td><td><span>Mime-Type</span></td><td><span>Size</span></td><td width="35%"><span>Status</span></td>';
        for (var key in data['ext_objects']) 
        {
            var dict = data['ext_objects'][key];
            var row = '<tr><td>' + dict['req'] + '</td><td><a href="' + dict['full_url'] + '">' + key + '</a></td><td>' + dict['mime_type'] + '</td><td>' + dict['size'] + '</td><td>' + StatusStyleExtItem(dict['status_msg'], dict) +' </td></tr>';
            listhtml += row;
        }
        listhtml = '<table width="100%">' + listhtml + '</table><br>';
        
        $("#css_resources").html(listhtml);
        $("#css_resources").css('display', 'block');
        
        $("#pre_output").html('');
        $("#post_output").html('');
        
        $("#css_output").html('');
        
        var arr = CmpVals(data, 'requests');
        $("#pre_output").append('<p>' + arr[0] + ' requests</p>');
        $("#post_output").append('<p>' + arr[1] + ' requests (' + PcDiff(data, 'requests') + '%)</p>');
                
        $("#post_output").append('<p></p>');
        $("#pre_output").append('<p></p>');
        
        arr = CmpVals(data, 'ext_objects');
        $("#pre_output").append('<p>' + arr[0] + ' ext. objects</p>');
        $("#post_output").append('<p>' + arr[1] + ' ext. objects (' + PcDiff(data, 'ext_objects') + '%)</p>');
        
        arr = CmpVals(data, 'ext_size');
        $("#pre_output").append('<p>' + arr[0] + ' bytes ext. obj. size</p>');
        $("#post_output").append('<p>' + arr[1] + ' bytes ext. obj. size (' + PcDiff(data, 'ext_size') + '%)</p>');
        
        arr = CmpVals(data, 'img_size');
        $("#pre_output").append('<p>' + arr[0] + ' bytes ext. image size</p>');
        $("#post_output").append('<p>' + arr[1] + ' bytes ext. image size (' + PcDiff(data, 'img_size') + '%)</p>');
                
        arr = CmpVals(data, 'css_size');
        $("#pre_output").append('<p>' + arr[0] + ' bytes CSS size</p>');
        $("#post_output").append('<p>' + arr[1] + ' bytes CSS size (' + PcDiff(data, 'css_size') + '%)</p>');
        
        arr = CmpVals(data, 'total_size');
        $("#pre_output").append('<p>' + arr[0] + ' bytes uncompressed' + '</p>');
        $("#post_output").append('<p>' + arr[1] + ' bytes uncompressed (' + PcDiff(data, 'total_size') + '%)</p>');
        
        arr = CmpVals(data, 'total_gzip_size');
        $("#pre_output").append('<p>' + arr[0] + ' bytes gzipped</p>');
        $("#post_output").append('<p>' + arr[1] + ' bytes gzipped ('+ PcDiff(data, 'total_gzip_size') +'%)</p>');
        
        if (data['post']['imgoptim_reduction']) {
            arr = CmpVals(data, 'imgoptim_reduction');
            $("#post_output").append('<br><p>' + arr[1] + ' bytes (img optimization)</p>');
        }
        
        $("#css_output").html('<pre>' + data['css_output'] + '</pre>');
        $("#css_downloadlink").html('<a href="' + data['css_link'] + '">⇓ Download Optimized CSS</a>')
        $("#css_output_container").css('display', 'block');
        
        ShowLoader(0);
    });    
}

/* calculate percentage difference between two values
   and format as a clean human-readable string */
function PcDiff (data, key)
{
    var a = data['post'][key], 
        b = data['pre'][key], 
        diff;
    
    if (b == 0 && a)
        return '100';
    else if (a == 0 && b == 0)
        return '0';
    
    diff = ((a/b) - 1.0) * 100;
    diff = diff.toFixed(1);
    
    if (diff >= 0)
        diff = '+' + diff;
    return diff;
}

// style external object item in Resources list
function StatusStyleExtItem (string, item)
{
    var status = item['status'], converted = item['converted'];
    
    if (status == 'warn')
        return '<u>' + string + '</u>';
    else if (status == 'err')
        return '<em>' + string + '</em>';
    else if (converted)
        return '<strong>' + string + '</strong>';
    return string;
}

/* set style tags for smaller/larger values in pairs
 for the result of the CSS Optimizer */
function CmpVals (data, key)
{
    var a = data['pre'][key], b = data['post'][key], na, nb;
    if (a < b) 
    { 
        na = '<strong>' + a + '</strong>';
        nb = '<em>' + b + '</em>';
    }
    else if (a == b)
    {
        na = a;
        nb = b;
    }
    else
    {
        nb = '<strong>' + b + '</strong>';
        na = '<em>' + a + '</em>';
    }
    return [na, nb]
}

function ReadCookie (name) 
{
    var nameEQ = name + "=", ca = document.cookie.split(';'), c, i;
    for (i = 0; i < ca.length; i++) 
    {
        c = ca[i];
        while (c.charAt(0) == ' ') 
            c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) == 0) 
            return c.substring(nameEQ.length, c.length);
    }
    return null;
}

function SetCookie (val)
{
    document.cookie = val + '; expires=Monday, 31-Dec-2081 05:00:00 GMT; path=/';
}

function URLFieldKeyHandler (e)
{
    if (e.keyCode) 
        keycode=e.keyCode;
    else 
        keycode=e.which;

    if (keycode != 13)
        return;
        
    OptimizeCSS();
}