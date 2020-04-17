String getcsstheme() {
// Light theme is after common, far far away :P
final String common = '''/* General theme */

body {
    margin: 24px;
    font-family: sans-serif;
    font-size: 15px;
    font-weight: regular;
}

p {
   line-height: 1.2;
}

/* Page title */

h3 {
	font-size: 20px;
	font-weight: bold;
}

/* Page title reference */

h3 small i {
    display: block;
    float: right;
    font-weight: normal;
    margin-top: 5px;
}


/* Page subtitle */

b i {
	font-size: 15px;
	display: block;
	margin-top: -12px;
	margin-bottom: 20px;
}

/* Citation */

blockquote {
	margin-right: 20px
}

blockquote p {
	margin-top: 30px;
}

/* Citation reference */

blockquote small i {
    display: block;
    text-align: right;
    margin-top: -15px;
    margin-right: 0;
    padding-top: 0;
}

/* Navigation button */

div.app-office-navigation {
    margin-top: 20px;
}

.app-office-navigation a {
    display: block;
    text-align: center;
    padding: 13px;
    margin-top: 10px;
    font-size: 17px;
    text-decoration: none;
    border: 1px solid;
}

/* Verse styling with optional line-wrap support */

.verse {
    display: block;
    float: left;
    width: 25px;
    text-align: right;
    margin-top: 4px;
    margin-left: -30px;
    font-size: 10px;
}

.line .verse {
   margin-left: -30px;
}

.line-wrap .verse {
   margin-left: -55px;
}

.line {
   display: block;
   margin-bottom: 5px;
}

.line:focus, div.antienne:focus {
    padding-left: 2px;
}

.line-wrap:focus {
    padding-left: 27px;
}

.line-wrap {
   display: block;
   padding-left: 25px;
   text-indent: -25px;
   margin-bottom: 1px;
}

/* Mark currently selected verse */

:focus {
    outline: none;
    border-left-width: 2px;
    border-left-style: solid;
    margin-left: -4px;
}

/* Verse inflection */

sup {
   vertical-align: baseline;
   position: relative;
   top: -0.4em;
}

.underline {
    text-decoration: underline;
}

/* Antiennes */

.antienne-title {
   font-style: italic;
   font-weight: bold;
}

/* Workaround: hide images (unsupported) */

img {
   display: none;
}

/* Highlight search keyword */

mark {
    background: transparent;
    font-weight: bold;
    text-decoration: underline;
    text-decoration-style: dotted;
}''';

final String light_theme = '''/* General theme */

body {
    background-color: rgba(239, 227, 206, 1);
    color: rgba(93, 69, 26, 1);
}

font[color='#cc0000'], font[color='#ff0000'], font[color='#CC0000'], font[color='#FF0000'] {
    color: rgba(191, 35, 41, 1);
}
font[color='#000000'] {
    color: rgba(93, 69, 26, 1);
}

/* Navigation button */

.app-office-navigation a {
    color: rgba(93, 69, 26, 1);
    border-color: rgba(93, 69, 26, 1);
}

.app-office-navigation a:active, .app-office-navigation a.active {
    color: rgba(93, 69, 26, 1);
    background-color: rgba(239, 227, 206, 1);
}

/* Verse styling with optional line-wrap support */

.verse {
    color: rgba(191, 35, 41, 1);
}

/* Mark currently selected verse */

:focus {
    border-left-color: rgba(191, 35, 41, 1);
}

/* Antiennes */

.antienne-title {
   color: rgba(191, 35, 41, 1);
}

/* Highlight search keyword */

mark {
    color: rgba(93, 69, 26, 1);
}''';

String cssTheme = common+light_theme;

return cssTheme;
}