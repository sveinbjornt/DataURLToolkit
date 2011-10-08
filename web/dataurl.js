
function ShowPage (pname)
{
    // show relevant block for the page
	$(".page").css("display", "none");
	$("#body_" + pname).css("display","block");
	
	// Remove selected style from all, add to selected item
	$(".litem").attr("id","");
	$('li[name=' + pname + ']').attr("id", 'selected');
}

function HandleFileSelect(evt) 
{
    if (!HasFileAPIs()) 
    {
        var frame = document.getElementById('postframe');
        frame.onload = DataURLLoaded;
        $("#upload-form").submit();
        
    }
    else
    {
        var files = evt.target.files; // FileList object
    	var file = files[0];
    	ReadDataFile(file);
    }
}

function DataURLLoaded ()
{
    if ($("#postframe").contents().text() == '') { return; }
    
    var dict = eval('(' + $("#postframe").contents().text() + ')');
    
    $("#dataurltextarea").html(dict['dataurl']);
	$("#dataurlfilename").html(dict['filename']);
	$("#droparea").css('display', 'none');
	$("#dataurlfilesize").html('Data URL Size: ' + dict['size'] + ' bytes<br>Gzipped URL size: ' + dict['gzipsize'] + ' bytes<br>Original size: ' + dict['origsize'] + ' bytes');
	if (dict['image']) {
		$("#dataurlimg").html('<img src="' + dict['dataurl'] + '">')
	} else {
		$("#dataurlimg").html('Not an image');
	}
	$("#dataurldisplay").css('display', 'block');
}

function Init ()
{
    document.getElementById('fileinput').addEventListener('change', HandleFileSelect, false);
    
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
    	$("#fileselectform").css('display', 'block');
	}
	else
	{
	}
	
    if (window.location.hash)
    {
	    ShowPage(window.location.hash.substring(1)); 
	}
	else
	{
	    ShowPage('about');
	}
}

function HasFileAPIs ()
{
    return (window.File && window.FileReader && window.FileList && window.Blob);
}

function ReadDataFile (file)
{
	var reader = new FileReader();
	
	// Handler function called once file is loaded.
	reader.onload = (function(theFile) {
  		return function(e) {
			var suffix = theFile.name.split('.').pop();
			$("#dataurltextarea").html(e.target.result);
			$("#dataurlfilename").html(theFile.name)
			$("#droparea").css('display', 'none');
			$("#dataurlfilesize").html('Data URL Size: ' + e.target.result.length + ' bytes<br>Original size: ' + theFile.size + ' bytes');
			if (suffix == 'jpg' || suffix == 'png' || suffix == 'gif' || suffix == 'jpeg' ||
				suffix == 'JPG' || suffix == 'PNG' || suffix == 'GIF' || suffix == 'JPEG') {
				$("#dataurlimg").html('<img src="' + e.target.result + '">')
			} else {
				$("#dataurlimg").html('Not an image');
			}
			$("#dataurldisplay").css('display', 'block');
	};})(file);

	// Read in the image file as a data URL.
	reader.readAsDataURL(file);
}

// Function drop file
function handleDrop (event)
{
	event.preventDefault();
	event.stopPropagation();
 	var dt = event.dataTransfer;
 	var files = dt.files;
	var file = files[0];
	ReadDataFile(file);
}

function OptimizeCSS ()
{
	var limit = $('#css_sizelimit').val();
	var compress = $('input:checkbox[name=compress]:checked').val();
	
	$('#css_spinner').css('display', 'block');
	
	var href = '/cgi-bin/dataurl.pl?action=optimize&compress=' + compress + '&size_limit=' + limit + '&css_file_url=' + $('#cssurl').val()
	$.get(href, function(data) {
		if (data == undefined) {
			 alert("ERROR:  NO DATA FROM SERVER.");
		}
		
		$("#pre_output").html('');
		$("#post_output").html('');
		
		$("#css_output").html('');
		
		var arr = cmp(data, 'requests');
		$("#pre_output").append('<p>' + arr[0] + ' requests</p>');
		$("#post_output").append('<p>' + arr[1] + ' requests (' + perc_diff(data, 'requests') + '%)</p>');
				
		$("#post_output").append('<p></p>');
		$("#pre_output").append('<p></p>');
		
		var arr = cmp(data, 'ext_objects');
		$("#pre_output").append('<p>' + arr[0] + ' ext. objects</p>');
		$("#post_output").append('<p>' + arr[1] + ' ext. objects (' + perc_diff(data, 'ext_objects') + '%)</p>');
		
		var arr = cmp(data, 'ext_size');
		$("#pre_output").append('<p>' + arr[0] + ' bytes ext. obj. size</p>');
		$("#post_output").append('<p>' + arr[1] + ' bytes ext. obj. size (' + perc_diff(data, 'ext_size') + '%)</p>');
				
		var arr = cmp(data, 'img_size');
		$("#pre_output").append('<p>' + arr[0] + ' bytes ext. image size</p>');
		$("#post_output").append('<p>' + arr[1] + ' bytes ext. image size (' + perc_diff(data, 'img_size') + '%)</p>');
		
		var arr = cmp(data, 'css_size');
		$("#pre_output").append('<p>' + arr[0] + ' bytes CSS size</p>');
		$("#post_output").append('<p>' + arr[1] + ' bytes CSS size (' + perc_diff(data, 'css_size') + '%)</p>');
		
		var arr = cmp(data, 'total_size');
		$("#pre_output").append('<p>' + arr[0] + ' bytes uncompressed' + '</p>');
		$("#post_output").append('<p>' + arr[1] + ' bytes uncompressed (' + perc_diff(data, 'total_size') + '%)</p>');
		
		var arr = cmp(data, 'total_gzip_size');
		$("#pre_output").append('<p>' + arr[0] + ' bytes gzipped</p>');
		$("#post_output").append('<p>' + arr[1] + ' bytes gzipped ('+ perc_diff(data, 'total_gzip_size') +'%)</p>');
		
		
		
		$("#css_output").html('<pre>' + data['css_output'] + '</pre>');
		$("#css_downloadlink").html('<a href="' + data['css_link'] + '">⇓ Download Optimized CSS</a>')
		$("#css_output_container").css('display', 'block');
		// ProcessCSS(data);
		$('#css_spinner').css('display', 'none');
	});	
}

function perc_diff (data, key)
{
	var a = data['post'][key];
	var b = data['pre'][key];
	if (b == 0 && a) { return '100'; } else if (a == 0 && b == 0) { return '0'; }
	
	var diff = ((a/b) - 1.0) * 100;
	diff = diff.toFixed(1)
	if (diff >= 0) { diff = '+' + diff; }
	return diff;
}

function cmp (data, key)
{
	var a = data['pre'][key]; 
	var b = data['post'][key];
	var na,nb;
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