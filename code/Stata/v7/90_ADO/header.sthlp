{smcl}
{* *! * version 1.2  AH 16 Aug 2021 }{...}
{viewerdialog header "dialog header"}{...}
{viewerjumpto "Syntax" "header##syntax"}{...}
{viewerjumpto "Description" "header##description"}{...}
{viewerjumpto "Options" "header##options"}{...}
{viewerjumpto "Examples" "header##examples"}{...}
{p2colset 1 18 20 2}{...}
{p2col:{bf:[T] header} {hline 2}}Generates header for descriptive tables{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:header} {varname}
{ifin}
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sav:ing(string)}}saves table header under filepath specified in string{p_end}
{synopt:{opt nopercent}}suppress percent estimate{p_end}
{synopt:{opt percentsign}}add percent sign{p_end}
{synopt:{opt freqlab(string)}}add label before frequencies{p_end}
{synopt:{opt brackets}}replaces parentheses with brackets{p_end}
{synopt:{opt midpoint}}use midpoint as separator for decimals{p_end}
{synopt:{opt freqf:ormat(string)}}formats frequencies according to stata format specified in string{p_end}
{synopt:{opt percentf:ormat(string)}}formats percentages according to stata format specified in string{p_end}
{synopt:{opt labelf:ormat(string)}}formats label column according to stata format specified in string{p_end}
{synopt:{opt clean(string)}}shows clean output{p_end}
{synopt:{opt varsu:ffix(string)}}renames all variables in table with suffix{p_end}
{synopt:{opt pv:alue(string)}}adds column for pvalues{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt header} generates headers for tables with summary statistics. Tables are stratified by varname. Rows with summary statistics can be appended to the table header using the user-written programs percentages.ado and sumstats.ado. 

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
