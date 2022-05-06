{smcl}
{* *! * version 1.2  AH 18 Apr 2021 }{...}
{viewerdialog colprc "dialog colprc"}{...}
{viewerjumpto "Syntax" "colprc##syntax"}{...}
{viewerjumpto "Description" "colprc##description"}{...}
{viewerjumpto "Options" "colprc##options"}{...}
{viewerjumpto "Examples" "colprc##examples"}{...}
{p2colset 1 20 20 2}{...}
{p2col:{bf:[T] colprc} {hline 2}} Tabulates categorical variables {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:colprc} {varname} stratavar 
{ifin}
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt append(string)}}append output to table specified in string{p_end}
{synopt:{opt head:ing(string)}}add row with heading specified in string{p_end}
{synopt:{opt nohead:ing}}suppress heading row{p_end}
{synopt:{opt nomi:ssings}}excludes observations with missing values in varname from analysis {p_end}
{synopt:{opt drop(stringlist)}}suppress output for levels of varname specified in stringlist{p_end}
{synopt:{opt nopercent}}suppress colprc{p_end}
{synopt:{opt columnt:otals}}report column totals in headings row{p_end}
{synopt:{opt clean(string)}}show clean version of table in output{p_end}

{syntab:Format}
{synopt:{opt freqf:ormat(string)}}formats frequencies according to Stata format specified in string{p_end}
{synopt:{opt percentf:ormat(string)}}formats colprc according to Stata format specified in string{p_end}
{synopt:{opt labelf:ormat(string)}}formats label column according to Stata format specified in string{p_end}
{synopt:{opt pf:ormat(string)}}formats pvalue according to stata format specified in string{p_end}
{synopt:{opt ind:ent(integer)}}indent labels by the number of blanks specified, (default=2){p_end}
{synopt:{opt percentsign}}add percent sign{p_end}
{synopt:{opt brackets}}report parentheses with brackets{p_end}
{synopt:{opt midpoint}}use midpoint as separator for decimals{p_end}

{syntab:P-value}
{synopt:{opt exact}}report Fisher's exact test{p_end}
{synopt:{opt chi}}report Pearson's chi-squared{p_end}
{synopt:{opt missingcode(integer)}}excludes specified value from chi-squared and Fisher's exact statistics{p_end}

{syntab:Advanced}
{synopt:{opt varsu:ffix(string)}}rename all variables in table with suffix{p_end}
{synopt:{opt plevel(integer)}}reports the p-value in the level specified in integer{p_end}
{synopt:{opt var(string)}}overwrites values in var{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt colprc} produces a two-way table (varname x stratavar) of column percentages and frequency counts and appends the formatted table to an existing table created with the user-written header.ado, colprc.ado or sumstats.ado. 

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. header foreign}{p_end}
{phang}{cmd:. header foreign, saving("Table 1") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) percentsign pvalue}{p_end}
{phang}{cmd:. recode price (min/4999 =1 "<5,000") (5000/9999 =2 "5,000-9,999") (10000/max =3 "10,000+"), gen(price_cat)}{p_end}
{phang}{cmd:. colprc price_cat foreign, append("Table 1") percentformat(%3.1fc) freqf(%5.0fc) heading("Price, USD") clean chi percentsign} {p_end}

		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch
