%option yywrap
%option stack
%{
//Pasat Ionut 334CC
#include <iostream>
using namespace std;

int indent = 0;
int quote_no = 0;
int list_no = 0;
int in_paragraph = 0;
int in_list = 0;
int par_prop_found = 0;
string setext_title;
void print_indentation(int indent) {
  for (int i = 0; i < indent; i++) {
    cout << "   ";
  }
}
%}

blankline (\n[-\*]+\n)
title [a-zA-Z0-9][a-zA-Z0-9 ]*
paragraph [a-zA-Z0-9\("]
link \[[a-zA-Z0-9 ]+\]
url \(.+\)
image (!\[[a-zA-Z0-9 ]*\])
pathtoimg \(.+\)
boldit2 [*_]{2}([^*_\n]+)[*_]{2}
boldit1 [*_]([^*_\n]+)[*_]
list_item ([0-9]\." "|\*" "|\+" "|-" ")


%s ATX_TITLE
%s SETEXT_TITLE
%s PARAGRAPH
%s ACCENTUATED
%s BLOCKQUOTE
%s LIST
%s TRASH

%%
"#"+  { 
  //atx start
  indent = yyleng;
  BEGIN(ATX_TITLE);
}

^{title}\n(=|-) {
  //setext start
  setext_title = yytext;
  BEGIN(SETEXT_TITLE);
}

{blankline} {
  //blankline
  print_indentation(indent);
  cout << "////////////" << endl;
}

^{paragraph} {
  //paragraph starts at the start of a line
  if (in_paragraph == 0) {
    print_indentation(indent);
    cout << ":" << yytext;
  }
  else {
    cout << yytext;
  }
  in_paragraph = 1;
  BEGIN(PARAGRAPH);
}

^{list_item} {
  //first item in a list
  print_indentation(indent + 1);
  in_list = 1;
  cout << "[";
  BEGIN(LIST);
}

{link}/{url} {
  //link followed by the url
  if (in_paragraph) {
    cout << yytext[0] << "@" << yytext + 1 << endl;
    BEGIN(TRASH);
  } else {
    print_indentation(indent);
    cout << yytext[0] << "@" << yytext + 1 << endl;
    BEGIN(TRASH);
  }
}

{image}/{pathtoimg} {
  //image followed by its path
  if (in_paragraph) {
    cout << yytext[1] << "!" << yytext + 2 << endl;
    BEGIN(TRASH);
  } else {
    print_indentation(indent);
    cout << yytext[1] << "!" << yytext + 2 << endl;
    BEGIN(TRASH);
  }
}


{boldit1} {
  //bold/italic between only 1 symbol
  if (in_paragraph) {
    yytext[yyleng - 1] = 0;
    cout << "<" << yytext + 1 << ">";
  }
  else {
    print_indentation(indent);
    yytext[yyleng - 1] = 0;
    cout << "<" << yytext + 1 << ">" << endl;
  }
}

{boldit2} {
  //bold/italic between 2 symbols
  if (in_paragraph) {
    yytext[yyleng - 2] = 0;
    cout << "<" << yytext + 2 << ">";
  }
  else {
    print_indentation(indent);
    yytext[yyleng - 2] = 0;
    cout << "<" << yytext + 2 << ">" << endl;
  }
}


^"> " {
  //quotes
  print_indentation(indent + 1);
  BEGIN(BLOCKQUOTE);
}



<SETEXT_TITLE>"-"+ {
  //setext title followed by -
  if (setext_title.size() - 3 == yyleng) {
    setext_title[setext_title.size() - 1] = 0;
    indent = 2;
    print_indentation(indent);
    cout << "+ " << setext_title;
  }
  BEGIN(TRASH);
}

<SETEXT_TITLE>"="+ {
  //setext title followed by =
  // -3 because in the first rule it had to contain 1 of the -/=
  if (setext_title.size() - 3 == yyleng) {
    setext_title[setext_title.size() - 1] = 0;
    indent = 1;
    print_indentation(indent);
    cout << "+ " << setext_title;
  }
  BEGIN(TRASH);
}


<ATX_TITLE>{title}    {
    print_indentation(indent);
    cout << "+ " << yytext << endl;
  }

<ATX_TITLE>#*\n  {
  //delete the rest # if they exist
  BEGIN(INITIAL); 
}

<BLOCKQUOTE>[^>]+[ \n] {
  yytext[yyleng - 1] = 0;
  //coutning the words
  quote_no++;
  cout << '"' << yytext << " ";
}

<BLOCKQUOTE>"> ".+[ \n] {
  yytext[yyleng - 1] = 0;
  quote_no++;
  if (quote_no == 5) {
    cout << yytext + 2 << '"' << endl;
    //reset if done and start over
    quote_no = 0;
    BEGIN(INITIAL);
  }
}

<BLOCKQUOTE>"> ".+\n\n {
  //end of the blockquote
  yytext[yyleng - 2] = 0;
  cout << yytext + 2 << '"' << endl;
  quote_no = 0;
  BEGIN(INITIAL);

}

<PARAGRAPH>\n\n {
  //end of the paragraph
  if (par_prop_found == 0) {
    cout << ":";
  }
    cout << endl;
    in_paragraph = 0;
    par_prop_found = 0;
    BEGIN(INITIAL);
}

<PARAGRAPH>[a-zA-Z0-9 ,\(\)\[\]] {
  //character by character
  if (par_prop_found == 0) {
    cout << yytext;
  }
}

<PARAGRAPH>".;:[(!?" {
  //end of the first sentence
  if (par_prop_found == 0) {
    cout << ":";
  } 
  par_prop_found = 1;
}

<PARAGRAPH>\n|\t {
  //make it a sentence with spaces
  cout << " ";
}

<PARAGRAPH>{link}/{url} {
  //if paragraph contains links
  cout << yytext[0] << "@" << yytext + 1;
  BEGIN(TRASH);
}

<PARAGRAPH>{image}/{pathtoimg} {
  //if paragraph contains images
  cout << yytext[1] << "!" << yytext + 2;
  BEGIN(TRASH);
}

<LIST>[^\n]\n {
  cout << "]" << endl;
}

<LIST>[^\n]\n\n {
  //end of list
  cout << "]" << endl << endl;;
}

<TRASH>\(.+\)\n {
  /* deleted */
  if (in_paragraph == 1) {
    BEGIN(PARAGRAPH);
  } else {
    BEGIN(INITIAL);
  }
}

<TRASH>-+ {
  /* deleted */
  BEGIN(INITIAL);
}

<TRASH>[=]+ {
  /* deleted */
  BEGIN(INITIAL);
}

<TRASH>.*\n {
  /* deleted */
  if (in_paragraph == 1) {
    BEGIN(PARAGRAPH);
  } else if (in_list == 1) {
    BEGIN(LIST);
  } else {
    BEGIN(INITIAL);
  }
}

^[\n\t ]|. {
  /* do nothing */
}

%%


int yywrap() {
  return 1;
}

int main(int argc, char **argv)
{
  int result;
  
  if (argc > 1) {
    yyin = fopen(argv[1], "r");
    if (!yyin) {
      perror(argv[1]);
      return 1;
    }
  }
  
  result = yylex();
  
  if (result == 0) {
    /* everything's okay */
  } else {
    cout << "Processing failed with code " << result << endl;
  }
  
  return result;
}
