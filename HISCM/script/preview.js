// TF ºä¾î ¿µ¿ª
function TrustFormWrite(id, filename, controlName, domainName, width, height)
{
	var obj = "";
		obj += "<OBJECT id='"+id+"' classid='CLSID:4DA55DF4-4825-44CF-9790-4D29E8F02AC7' width='"+width+"' height='"+height+"'>";
		obj += "<PARAM name='src' value='"+filename+"'/>";
		obj += "<PARAM name='controlName' value='"+controlName+"'/>";
		obj += "<PARAM name='domainName' value='"+domainName+"'/>";
		obj += "</OBJECT>";
		
	document.write(obj);
}

function TFMenuWrite(id, url, width, height)
{ 	
	var obj = "" ;
	obj += "<OBJECT id='"+id+"' classid='CLSID:81FF07A5-9782-45D9-A516-17601D57397D' width='"+width+"' height='"+height+"'>";
	obj += "<PARAM name='MenuItem' value='"+url+"'/>" ;
	obj += "</OBJECT>" ;

	document.write(obj);
}