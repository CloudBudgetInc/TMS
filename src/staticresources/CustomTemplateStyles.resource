/*for print receipts/acknowledgements */
@page{size: 8.5in 14in;}
@page :left { 
	margin-top: 0mm;
	margin-bottom: 0mm; 
	margin-left: 2mm; 
	padding-right: 10mm;
}
@page :right { 
    margin-top: 0mm;
	margin-bottom: 0mm; 
	margin-left: 2mm; 
	padding-right: 10mm;
}

body { color: #000000; font-family: Times; font-size: 12pt; margin: 0px; padding: 0px; text-align: center;}
a {color: #000000;}

#page
{
    padding: 1.5cm; 
    padding-bottom: 0; 
    width: 8.5in; 
    height: auto;
}

#letterhead
{
	display: none;
    width: 100%;
    text-align: center;
    margin: -0.75cm -1.5cm 0 -1.75cm;
}

#receiptTitle
{
    position: absolute; 
    top: 3cm; 
    left: 0.75cm; 
    font-size: 18px; 
    font-weight: bold;
}

#receiptAddressBlock
{
    position: absolute; 
    top: 5cm; 
    left: 1.55cm;
}

#TMSAddress
{
    position: absolute; 
    top: 0.75cm; 
    right: 0cm;
    padding-right: 1cm;
    text-align: center; 
    font-size: 13px; 
    width: auto;
    white-space: nowrap;
}


#signatureBlock
{
	position: absolute; 
    top: 0.75cm; 
    right: 1.5cm; 
    text-align: center; 
    font-size: 13px; 
    width: auto;
}


#receiptInfo
{
    position: absolute; 
    top: 5cm; 
    right: 0in;  
    text-align: right; 
    font-size: 12px; 
    width: auto; 
    padding-right: 1cm;
    max-width: 50%;
}

#receiptInfo td.receiptInfoLabel
{
    text-align: right;
}

#receiptInfo td.receiptInfo
{
    width: auto; 
    font-weight: bold;
}

#CRAWebsite
{
    position: absolute; 
    top: 8.5cm; 
    width: 100%; 
    text-align: center;
}

#receiptLetter
{
    position: absolute; 
    top: 10cm; 
    left: 0cm; 
    padding-left: 1.55cm; 
    padding-right: 1.55cm;
}

#couponAddressBlock
{
    position: absolute; 
    left: 1.05cm; 
    top: 12.5in;
}

#scanline
{
    position: absolute; 
    top: 13.25in; 
    left: 1.05cm; 
    font-family: Courier;
}


/*
.page {width: 8.3in; height: auto; min-height: 13.98in; padding: 0px; margin: 0px auto; position: relative; text-align: left;}
.letter {width: 90%; padding-bottom: 10px; margin: 0px auto; margin-bottom: 10px;}
.receipt {width: 90%; position: absolute; left: 5%; bottom: 0px; border-top: 2px gray dashed;}
.receiptSignature {text-align: center; padding-top: 20px; padding-bottom: 40px;}
.footer {vertical-align: bottom; font-size: .7em; font-style: italic;}
*/  
  
/************************/
/* GLOBAL               */
/************************/
.clear { clear: both; height: 0px; overflow: hidden; }
    
.hide { display: none; }
.left { text-align: left; }
.right { text-align: right; }
.center { text-align: center;}
.nowrap {width: auto; white-space: nowrap;}
Quicklinks
Profiles Chamber
Quick Console
Home
Quick Query
Execute Anonymous
Sobject fields
Quick ORG Describe
Replace API Names
Convert SF Id
Login As...
Options
Hide