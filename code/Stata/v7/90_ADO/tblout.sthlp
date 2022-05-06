{smcl}
{* *! * version 1.0  AH 16 Aug 2021 }{...}
{viewerdialog tblout "dialog tblout"}{...}
{viewerjumpto "Syntax" "tblout##syntax"}{...}
{viewerjumpto "Description" "tblout##description"}{...}
{viewerjumpto "Options" "tblout##options"}{...}
{viewerjumpto "Examples" "tblout##examples"}{...}
{p2colset 1 16 20 2}{...}
{p2col:{bf:[T] tblout} {hline 2}} Output table {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:tblout} using {it:filename} 
[{cmd:,}
{it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt clear}}specifies that it is okay to replace the data in memory, even though the current data have not been saved to disk.}{p_end}
{synopt:{opt me:rge}}merges estimates in one cell{p_end}
{synopt:{opt al:ign}}align frequencies and percentages{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt tblout} loads tables generated with the user-written commands header.ado, colprc.ado or sumstats.ado in memory and prepares them for export into word or excel files. 

{marker examples}{...}
{title:Examples}

    Setup	
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. recode price (min/4999 =1 "<5,000") (5000/9999 =2 "5,000-9,999") (10000/max =3 "10,000+"), gen(price_cat)}{p_end}

    Generate table header 
{phang}{cmd:. header foreign, saving("Table 1") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) percentsign pvalue}{p_end}

    Append rows with frequencies and column percentages for variable price_cat to table header
{phang}{cmd:. colprc price_cat foreign, append("Table 1") percentformat(%3.1fc) freqf(%5.0fc) heading("Price, USD") clean chi percentsign} {p_end}

    Append rows with median and IQR table 
{phang}{cmd:. sumstats price foreign, append("Table 1") format(%5.0fc) median clean ttest} {p_end}

    Load table in memory and prepare for export in word
{phang}{cmd:. tblout using "Table 1", clear merge align format("%15s")} {p_end}

    Export table in word
{phang}{cmd:. capture putdocx clear} {p_end}
{phang}{cmd:. putdocx begin, font("Arial", 8)} {p_end}
{phang}{cmd:. putdocx paragraph, spacing(after, 0)} {p_end}
{phang}{cmd:. putdocx text ("Table 1: Characteristics of cars by foreign"), font("Arial", 9, black) bold}{p_end}
{phang}{cmd:. putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)}{p_end}
{phang}{cmd:. putdocx table tbl1(., .), halign(right)  font("Arial", 8)}{p_end}
{phang}{cmd:. putdocx table tbl1(., 1), halign(left)}{p_end}
{phang}{cmd:. putdocx table tbl1(1, .), halign(center) bold}{p_end}
{phang}{cmd:. putdocx table tbl1(2, .), halign(center)  border(bottom, single)} {p_end}
{phang}{cmd:. putdocx save "Table 1.docx", replace} {p_end}
		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch
