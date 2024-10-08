%{
#include <stdio.h> 
#include <stdbool.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
void yyerror(char *);
int yylex();
extern int lineno;
extern FILE * tokenFile;
extern FILE * parsedFile;

void addToFile(char * s, int t);
void INThandler(int sig);
int addtoken(char *s, char *token_value);

%}
%union {
    char *sVal; 
}

%token <sVal> INTEGER
%token <sVal> VAR
%token <sVal> DOUBLE
%token <sVal> INT FLOAT BIG SMALL IF ELSE RETURN SIZE
%token <sVal> ADD_OP SUB_OP DIV_OP MULT_OP POW_OP MOD_OP ASSIGN COMP_ASSIGN_ADD
%token <sVal> LESS_THAN LESS_THAN_EQ GREAT_THAN GREAT_THAN_EQ NOT_EQ COMPLEMENT EQUAL_TO
%token <sVal> OR AND NOT BIT_OR BIT_AND BIT_NOT BIT_XOR NOT_OP
%token <sVal> TERNARY COLON SEMI RIGHT_ACCESS LEFT_ACCESS  
%token <sVal> LEFT_PAREN RIGHT_PAREN LEFT_CURLY_BRACE RIGHT_CURLY_BRACE LEFT_BRACE RIGHT_BRACE
%token <sVal> SINGLE_LINE_COMMENT RIGHT_ANGLE LEFT_ANGLE SET LOOP FINALLY PRINT FUNC  COMMA
%type <sVal> PROGRAM SETUP_STATEMENT COMPOUND_STATEMENT
%type <sVal> STATEMENT MUL_FUNC_STATMENT FUNC_STATEMENT LOOP_STATEMENT LOOP_CONDITION FINALLY_STMT IF_STATEMENT ELSE_STATEMENT CONDITIONAL_STATEMENT PRINT_STATEMENT
%type <sVal> FUNCTION_DEC_LIST PARAMETER_LIST PARAMETER  RETURN_STATEMENT PUSH_POP_STATEMENT PUSH_STMT POP_STMT SIZE_EXP SET_TYPE SET_STATEMENT_LIST SET_STATEMENT
%type <sVal> VEC_TYPE MIX_TYPE TYPE VAR_TYPE DEC_CONDITION VAR_LIST DEC_STATEMENT ASSIGN_STATEMENT EXPRESSION EXPRESSION_STMT ARITHMETIC_EXP MUL_EXP UNARY_EXPRESSION PRIMARY_EXP BOOLEAN_EXP BIT_WISE_EXP RELATIONAL_EXP ACCES_VAL
%type <sVal> FUNC_ACC_PARAM_LIST REF_TYPE FACTOR PRINTABLE FUNCTION_BODY SET_SIZE
%left OR
%left AND
%left LESS_THAN LESS_THAN_EQ GREAT_THAN GREAT_THAN_EQ EQUAL_TO NOT_EQ
%left ADD_OP SUB_OP
%left MULT_OP DIV_OP MOD_OP
%right NOT 
%right TERNARY
%%
PROGRAM:SETUP_STATEMENT COMPOUND_STATEMENT  { printf("IN CMPTN\n");  $$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2);  printf("IN Main\n");}
      ;
COMPOUND_STATEMENT: COMPOUND_STATEMENT STATEMENT  {$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);printf("%s\n",$$);  }
                  |  { $$= (char *)malloc(2); sprintf($$,""); } 

                  ;
/* there can be multiple fucntion declaration statements in the setup section but it must have one set statement */
MUL_FUNC_STATMENT: MUL_FUNC_STATMENT FUNC_STATEMENT {$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);}
                 | FUNC_STATEMENT {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
                 ;
SET_STATEMENT_LIST : SET_STATEMENT_LIST SET_STATEMENT  {$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);}
                   | SET_STATEMENT {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
                   ;
SETUP_STATEMENT: SET_STATEMENT_LIST {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
                 | SET_STATEMENT_LIST MUL_FUNC_STATMENT {$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);printf("%s\n",$$);}
               ;
/* all the statments that can be seen on the main section */
STATEMENT   : 
            LOOP_STATEMENT  SEMI  {$$ = (char *)malloc(strlen($1)+strlen(";")+1); sprintf($$, "%s\n;",$1); free($1);}
            | PUSH_POP_STATEMENT  SEMI {addToFile("PUSH_POP_STATEMENT", 2); $$ = (char *)malloc(strlen($1)+strlen(";")+1); sprintf($$, "%s\n;",$1); free($1);}
            | CONDITIONAL_STATEMENT {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s\n",$1); free($1);}
            | PRINT_STATEMENT {addToFile("PRINT_STATEMENT", 2);$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s\n",$1); free($1);}
            | DEC_STATEMENT  {addToFile("DEC_STATEMENT", 2);$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s\n",$1); free($1);}
            | EXPRESSION_STMT  {addToFile("EXPRESSION_STMT", 2);$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s\n",$1); free($1);}
            | ASSIGN_STATEMENT  SEMI {addToFile("ASSIGN_STATEMENT", 2);$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s\n",$1,$2); free($1);free($2);}
            ;
/* definition for the looping statement */
LOOP_STATEMENT : LOOP LEFT_PAREN LOOP_CONDITION RIGHT_PAREN COLON LEFT_ANGLE COMPOUND_STATEMENT RIGHT_ANGLE  
                    {$$= (char *)malloc(strlen("for ")+strlen("( ")+strlen($3)+ strlen(") ")+strlen(" : ")+strlen(" < ")+strlen($7)+strlen(" > ")+1); 
            sprintf($$, "for ( %s ) <\n %s >", $3,$7); 

            free($3); free($7);
            }
               | LOOP LEFT_PAREN LOOP_CONDITION RIGHT_PAREN COLON LEFT_ANGLE COMPOUND_STATEMENT RIGHT_ANGLE COLON FINALLY_STMT 
               {$$= (char *)malloc(strlen($1)+strlen("for ")+strlen(" ( ")+strlen($3)+ strlen(" ) ")+strlen(": ")+strlen("< ")+strlen($7)+strlen("> ")+strlen($9)+1); 
            sprintf($$, "for ( %s ):< %s > %s", $3,$7,$9); 
            free($3); free($7); free($9);
            }
               ;
LOOP_CONDITION : DEC_STATEMENT BOOLEAN_EXP SEMI ASSIGN_STATEMENT {addToFile("LOOP_STATEMENT", 2);$$= (char *)malloc(strlen($1)+strlen($2)+strlen($3)+ strlen($4)+1); 
            sprintf($$, "%s %s ;%s", $1,$2,$4); free($1); free($2); free($4);}

FINALLY_STMT : FINALLY COLON LEFT_ANGLE COMPOUND_STATEMENT RIGHT_ANGLE {$$= (char *)malloc(strlen($1)+strlen($2)+strlen($3)+ strlen($4)+strlen($5)+1); 
            sprintf($$, " %s :<%s>", $1,$4); free($1);free($4);
            }
 /* definition for the conditional statement with if else */
IF_STATEMENT: BOOLEAN_EXP TERNARY STATEMENT {addToFile("CONDITIONAL_STATEMENT", 2); 
                        $$= (char *)malloc(strlen($1)+strlen("?")+strlen($3)+1); 
                        sprintf($$, "%s?%s", $1,$3); 
                        free($1);free($3);
                        }
ELSE_STATEMENT: ELSE COLON STATEMENT
{$$= (char *)malloc(strlen("else")+strlen(":")+strlen($3)+1); sprintf($$, "else:%s",$3); free($3);}
            ;
CONDITIONAL_STATEMENT : RIGHT_ANGLE IF_STATEMENT ELSE_STATEMENT LEFT_ANGLE{$$= (char *)malloc(strlen("<")+strlen($2)+strlen($3)+ strlen(">")+1); 
            sprintf($$, "<%s%s>", $2,$3);  free($2); free($3);
            }
/* Print statement */
PRINT_STATEMENT: PRINT LEFT_PAREN PRINTABLE RIGHT_PAREN SEMI{$$= (char *)malloc(strlen("print")+strlen("(")+strlen($3)+ strlen($4)+strlen(")")+1); 
            sprintf($$, "print(%s%s);", $3,$4); free($3); free($4);
            }
/* Function declaration statement */
FUNC_STATEMENT: FUNC VAR  FUNCTION_DEC_LIST LEFT_ANGLE FUNCTION_BODY RIGHT_ANGLE  
            {$$= (char *)malloc(strlen("func")+strlen($2)+strlen($3)+ strlen("<\n")+strlen($5)+strlen(">\n")+1); 
            sprintf($$, "func %s %s<\n%s\n>\n", $2,$3,$5);  free($2); free($3); free($5); 
            }
FUNCTION_DEC_LIST :LEFT_PAREN PARAMETER_LIST SEMI  TYPE RIGHT_PAREN{addToFile("FUNC_STATEMENT",2);$$= (char *)malloc(strlen($1)+strlen($2)+strlen($3)+ strlen($4)+strlen($5)+1); 
            sprintf($$, "(%s;%s)", $2,$4);  free($2);  free($4);
            }
                |LEFT_PAREN SEMI TYPE RIGHT_PAREN
                {addToFile("FUNC_STATEMENT",2);
                $$= (char *)malloc(strlen("(")+strlen(";")+strlen($3)+ strlen(")")+1); 
                sprintf($$, "(;%s)", $3); free($3);}
PARAMETER_LIST : PARAMETER {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
              | PARAMETER_LIST COMMA PARAMETER  {$$= (char *)malloc(strlen($1)+strlen(",")+strlen($3)+1); sprintf($$, "%s,%s", $1,$3); free($1); free($3);}
            ;
                ;
PARAMETER : TYPE VAR {$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);}

FUNCTION_BODY : COMPOUND_STATEMENT RETURN_STATEMENT{$$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s%s",$1,$2); free($1);free($2);}
              ;

RETURN_STATEMENT : RETURN EXPRESSION SEMI {

addToFile("RETURN_STATEMENT",2); $$= (char *)malloc(strlen("return")+strlen($2)+strlen(";")+1);
             sprintf($$, "return %s;\n", $2); free($2);}
            ; 

/* Vector push pop statements */
PUSH_POP_STATEMENT : PUSH_STMT {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
                 | POP_STMT {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}

PUSH_STMT : VAR LEFT_ACCESS LEFT_BRACE EXPRESSION RIGHT_BRACE 
            {$$= (char *)malloc(strlen($1)+strlen("->")+strlen("[")+ strlen($4)+strlen("]")+1); 
            sprintf($$, "%s->[%s]", $1,$4); free($1); free($4);
            }
          | LEFT_BRACE EXPRESSION RIGHT_BRACE RIGHT_ACCESS VAR
          {$$= (char *)malloc(strlen("[")+ strlen($2)+strlen("]") +strlen("<-")+strlen($5)+1); 
            sprintf($$, "[%s]<-%s", $2,$5);  free($2); free($5);}
          ;
POP_STMT  :  VAR RIGHT_ACCESS LEFT_BRACE VAR RIGHT_BRACE 
            {$$= (char *)malloc(strlen($1)+strlen("<-")+strlen("[")+ strlen($4)+strlen("]")+1); 
            sprintf($$, "%s<-[%s]", $1,$4); free($1); free($4);
            }
          | LEFT_BRACE  RIGHT_BRACE LEFT_ACCESS VAR 
            {$$= (char *)malloc(strlen("[")+strlen("]")+strlen("->")+ strlen($4)+1); 
            sprintf($$, "[]->%s", $4); free($4);}
          | VAR RIGHT_ACCESS LEFT_BRACE RIGHT_BRACE {$$= (char *)malloc(strlen($1)+strlen("<-")+strlen("[")+strlen("]")+1); 
            sprintf($$, "%s<-[]", $1); free($1); free($4);
            }
          ;
SIZE_EXP: SIZE LEFT_BRACE VAR RIGHT_BRACE{$$= (char *)malloc(strlen("size")+strlen("[")+strlen($3)+ strlen("]")+1); 
            sprintf($$, "size[%s]", $3); free($3);}
         ;


/* Set statement */
SET_TYPE: INT   {$$ = (char *)malloc(strlen(" int")+1); sprintf($$, "int"); }
            |FLOAT {$$ = (char *)malloc(strlen(" float")+1); sprintf($$, "float");}
            ;
SET_SIZE: BIG {$$ = (char *)malloc(strlen("big")+1); sprintf($$, "big");}
            |SMALL {$$ = (char *)malloc(strlen("small")+1); sprintf($$, "small");}
            ;

SET_STATEMENT: SET SET_TYPE SET_SIZE SEMI { addToFile("SET_STATEMENT",2);
                    $$= (char *)malloc(strlen("set ")+strlen($2)+strlen($3)+ strlen(";")+1); 
                    sprintf($$, "set %s %s;\n", $2,$3);free($2); free($3);  }

/* Declaration Statements */
VEC_TYPE:LEFT_BRACE SET_TYPE RIGHT_BRACE 
        {$$= (char *)malloc(strlen("[")+strlen($2)+strlen("]")+1); sprintf($$, "[%s]", $2); free($2);}
            ; 
MIX_TYPE: SET_TYPE{$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
                 | VEC_TYPE{$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);} ;
TYPE : SET_TYPE {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
        | VEC_TYPE {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
        | LEFT_CURLY_BRACE SET_TYPE COLON MIX_TYPE RIGHT_CURLY_BRACE
        {$$= (char *)malloc(strlen(" { ")+strlen($2)+strlen(" : ")+ strlen($4)+strlen("}")+1); 
            sprintf($$, "{ %s : %s}", $2,$4);  free($2);free($4);
            }
        ;     

VAR_TYPE: INTEGER {$$ = (char *)malloc(strlen($1)+3); sprintf($$, " %s ",$1); free($1);} 
            | DOUBLE {$$ = (char *)malloc(strlen($1)+3); sprintf($$, " %s ",$1); free($1);}
DEC_CONDITION: ASSIGN VAR_TYPE  {$$ = (char *)malloc(strlen(" = ")+strlen($2)+1); sprintf($$, " = %s",$2);free($2);}
             | { $$= (char *)malloc(2); sprintf($$,""); } 
             ;
VAR_LIST: VAR_LIST COMMA VAR DEC_CONDITION {$$= (char *)malloc(strlen($1)+strlen(",")+strlen($3)+ strlen($4)+1); 
            sprintf($$, "%s,%s %s", $1,$3,$4); free($1); free($3); free($4);
            }
            |  VAR DEC_CONDITION {
   $$ = (char *)malloc(strlen($1)+strlen($2)+1); sprintf($$, "%s %s",$1,$2); free($1);free($2);}

DEC_STATEMENT: TYPE VAR_LIST SEMI { 
$$= (char *)malloc(strlen($1)+strlen($2)+strlen(" ; ")+1); sprintf($$, "%s %s;\n", $1,$2); 
                    free($1); free($2);}
            ;  
/* Assignment Statement */
ASSIGN_STATEMENT: VAR ASSIGN EXPRESSION {$$= (char *)malloc(strlen($1)+strlen(" = ")+strlen($3)+1); 
                        sprintf($$, "%s = %s", $1,$3); free($1); free($3);}
            ;

/* Expressions that make up boolean, arithmetic , bitwise operations */
EXPRESSION_STMT : EXPRESSION SEMI {$$ = (char *)malloc(strlen($1)+strlen(";")+1); 
                        sprintf($$, "%s;\n",$1); free($1);}
EXPRESSION : BOOLEAN_EXP  {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1); printf("%s",$$);}
           ;
ARITHMETIC_EXP : ARITHMETIC_EXP ADD_OP  MUL_EXP  {$$= (char *)malloc(strlen($1)+strlen(" + ")+strlen($3)+1); 
                    sprintf($$, "%s + %s", $1,$3); free($1);free($3);}
             
               | ARITHMETIC_EXP SUB_OP MUL_EXP {$$= (char *)malloc(strlen($1)+strlen(" - ")+strlen($3)+1); 
               sprintf($$, "%s - %s", $1,$3); free($1); free($3);}
             
               | MUL_EXP {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
	            ;

MUL_EXP : MUL_EXP MULT_OP  UNARY_EXPRESSION 
        {$$= (char *)malloc(strlen($1)+strlen(" * ")+strlen($3)+1); 
        sprintf($$, "%s * %s", $1,$3); 
        free($1); free($3);}
             
        | MUL_EXP DIV_OP UNARY_EXPRESSION {$$= (char *)malloc(strlen($1)+strlen(" / ")+strlen($3)+1); 
        sprintf($$, "%s / %s", $1,$3); free($1); free($3);}
             
        | UNARY_EXPRESSION  {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
        ;

UNARY_EXPRESSION : NOT_OP UNARY_EXPRESSION  {$$ = (char *)malloc(strlen("! ")+strlen($2)+1); sprintf($$, "! %s",$2); free($2);}
                 | BIT_NOT UNARY_EXPRESSION  {$$ = (char *)malloc(strlen("~ ")+strlen($2)+1); sprintf($$, "~ %s",$2); 
                            free($1);free($2);}
                 | PRIMARY_EXP  {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
 
PRIMARY_EXP  : LEFT_PAREN EXPRESSION RIGHT_PAREN {$$= (char *)malloc(strlen(" ( ")+strlen($2)+strlen(" ) ")+1); 
                sprintf($$, "(%s)", $2); free($2); }
             
             | FACTOR {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
             | REF_TYPE {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); free($1);}
             ; 

BOOLEAN_EXP : BOOLEAN_EXP AND BIT_WISE_EXP{
            $$= (char *)malloc(strlen($1)+strlen("and")+strlen($3)+1); 
            sprintf($$, "%sand%s", $1,$3); free($1);  free($3);}
             
            | BOOLEAN_EXP OR BIT_WISE_EXP  
            {$$= (char *)malloc(strlen($1)+strlen(" or ")+strlen($3)+1); 
                sprintf($$, "%sor%s", $1,$3); free($1);  free($3);}
             
            |BIT_WISE_EXP {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);}
            ;
BIT_WISE_EXP :BIT_WISE_EXP BIT_AND RELATIONAL_EXP  
            {$$= (char *)malloc(strlen($1)+strlen(" & ")+strlen($3)+1); sprintf($$, "%s & %s", $1,$3); free($1); free($3);}
             
             | BIT_WISE_EXP BIT_XOR RELATIONAL_EXP {$$= (char *)malloc(strlen($1)+strlen(" ^ ")+strlen($3)+1); 
             sprintf($$, "%s ^ %s", $1,$3); free($1); free($3);}
             
             | BIT_WISE_EXP BIT_OR RELATIONAL_EXP {$$= (char *)malloc(strlen($1)+strlen(" | ")+strlen($3)+1); 
             sprintf($$, "%s | %s", $1,$3); free($1); free($3);}
             
             | RELATIONAL_EXP {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);}
             ;
RELATIONAL_EXP : RELATIONAL_EXP LEFT_ANGLE ARITHMETIC_EXP 
            {$$= (char *)malloc(strlen($1)+strlen(" < ")+strlen($3)+1); sprintf($$, " %s < %s", $1,$3); free($1); free($3); }
             
               | RELATIONAL_EXP RIGHT_ANGLE ARITHMETIC_EXP 
               {$$= (char *)malloc(strlen($1)+strlen(" > ")+strlen($3)+1); sprintf($$, " %s > %s ", $1,$3); free($1); free($3);}
             
               | RELATIONAL_EXP GREAT_THAN_EQ ARITHMETIC_EXP 
               {$$= (char *)malloc(strlen($1)+strlen(" >= ")+strlen($3)+1); sprintf($$, " %s >= %s ", $1,$3); free($1); free($3);}
             
               | RELATIONAL_EXP LESS_THAN_EQ ARITHMETIC_EXP 
               {$$= (char *)malloc(strlen($1)+strlen(" <= ")+strlen($3)+1); sprintf($$, " %s <= %s ", $1,$3); free($1); free($3);}
             
               | RELATIONAL_EXP EQUAL_TO ARITHMETIC_EXP 
               {$$= (char *)malloc(strlen($1)+strlen(" == ")+strlen($3)+1); sprintf($$, " %s == %s", $1,$3); free($1); free($3);}
             
               | RELATIONAL_EXP NOT_EQ ARITHMETIC_EXP 
                {$$= (char *)malloc(strlen($1)+strlen(" <> ")+strlen($3)+1); sprintf($$, " %s <> %s ", $1,$3); free($1); free($3);}             
               |ARITHMETIC_EXP  {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);}
              ;

/* For accessing arrays/functions */
ACCES_VAL: ARITHMETIC_EXP {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);};
FUNC_ACC_PARAM_LIST: FUNC_ACC_PARAM_LIST COMMA FACTOR 
                        {$$= (char *)malloc(strlen($1)+strlen(",")+strlen($3)+1); sprintf($$, " %s ,%s ", $1,$3); free($1); free($3);}
                  | FACTOR {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);}
REF_TYPE: VAR LEFT_BRACE  ACCES_VAL RIGHT_BRACE  
            {$$= (char *)malloc(strlen($1)+strlen(" [ ")+strlen($3)+ strlen(" ] ")+1);
                     sprintf($$, "%s[%s]", $1,$3);
                     free($1);free($3); } /*Access vectors*/
            | VAR LEFT_PAREN FUNC_ACC_PARAM_LIST RIGHT_PAREN {$$= (char *)malloc(strlen($1)+strlen(" ( ")+strlen($3)+ strlen(" ) ")+1); 
            sprintf($$, "%s(%s)", $1,$3); free($1); free($3); 
            }/*Call Functions*/
            |VAR LEFT_PAREN RIGHT_PAREN {$$= (char *)malloc(strlen($1)+strlen("(")+strlen(")")+1); 
            sprintf($$, "%s()", $1); free($1); free($3); ; free($1); free($2);}
            ;

FACTOR : VAR  {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1);}
       | INTEGER {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); } 
       | DOUBLE {$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); } 
       | SIZE_EXP{$$ = (char *)malloc(strlen($1)+1); sprintf($$, "%s",$1); } 
       ;
PRINTABLE: EXPRESSION {$$ = (char *)malloc(strlen($1)+1); sprintf($$, " %s ",$1); free($1);};
         

/* input:

    | input statement
    ;

statement:
    VAR { printf("VAR\n"); }
    | INTEGER { printf("INTEGER\n"); }
    | DOUBLE { printf("DOUBLE\n"); }

    | INT { printf("INT\n"); }
    | FLOAT { printf("FLOAT\n"); }
    | BIG { printf("BIG\n"); }
    | SMALL { printf("SMALL\n"); }
    | IF { printf("IF\n"); }
    | ELSE { printf("ELSE\n"); }
    | RETURN { printf("RETURN\n"); }
    | SET { printf("SET\n"); }
    | LOOP { printf("LOOP\n"); }
    | FINALLY { printf("FINALLY\n"); }
    | PRINT { printf("PRINT\n"); }
    | FUNC { printf("FUNC\n"); }

    | ADD_OP { printf("ADD_OP\n"); }
    | SUB_OP { printf("SUB_OP\n"); }
    | DIV_OP { printf("DIV_OP\n"); }
    | MULT_OP { printf("MULT_OP\n"); }
    | MOD_OP { printf("MOD_OP\n"); }
    | POW_OP { printf("POW_OP\n"); }
    | ASSIGN { printf("ASSIGN\n"); }
    | COMP_ASSIGN_ADD { printf("COMP_ASSIGN_ADD\n"); }

    | BIT_OR { printf("BIT_OR\n"); }
    | BIT_AND { printf("BIT_AND\n"); }
    | BIT_NOT { printf("BIT_NOT\n"); }

    | OR { printf("OR\n"); }
    | AND { printf("AND\n"); }
    | NOT { printf("NOT\n"); }

    | LESS_THAN { printf("LESS_THAN\n"); }
    | LESS_THAN_EQ { printf("LESS_THAN_EQ\n"); }
    | GREAT_THAN { printf("GREAT_THAN\n"); }
    | GREAT_THAN_EQ { printf("GREAT_THAN_EQ\n"); }
    | NOT_EQ { printf("NOT_EQ\n"); }
    | COMPLEMENT { printf("COMPLEMENT\n"); }

    | RIGHT_ACCESS { printf("RIGHT_ACCESS\n"); }
    | LEFT_ACCESS { printf("LEFT_ACCESS\n"); }

    | LEFT_PAREN { printf("LEFT_PAREN\n"); }
    | RIGHT_PAREN { printf("RIGHT_PAREN\n"); }
    | LEFT_CURLY_BRACE { printf("LEFT_CURLY_BRACE\n"); }
    | RIGHT_CURLY_BRACE { printf("RIGHT_CURLY_BRACE\n"); }
    | LEFT_BRACE { printf("LEFT_BRACE\n"); }
    | RIGHT_BRACE { printf("RIGHT_BRACE\n"); }
    | TERNARY {printf("TERNARY\n");}
    | COLON { printf("COLON\n"); }
    | EOL { printf("EOL\n"); }


    | RIGHT_ANGLE{ printf("RIGHT_ANGLE\n");}
    | LEFT_ANGLE{ printf("LEFT_ANGLE\n");}
    | SINGLE_LINE_COMMENT { printf("SINGLE_LINE_COMMENT\n"); }
    ; */
%%

void yyerror(char *s) {
    printf("%s\n", s);/*Procedure to print out the error message...*/
}
extern FILE *yyin;
void INThandler(int sig) 
{

char c;
  // Catching the signal
  signal(sig,SIG_IGN);
  printf("\nDid you hit (Crtl-c)?\n Are you sure you want to close this program ? (Y/N)\n");
/*c  = getchar();
if (c=="y"||c=="Y") {
  fclose(tokenFile);
  fclose(parsedFile);
  free_token_list();
  exit(0);
}else {
signal(SIGINT,INThandler);
getchar();
} */
  fclose(tokenFile);
  fclose(parsedFile);
exit(0);
} 
int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    FILE *inputFile = fopen(argv[1], "r");
    if (inputFile == NULL) {
        perror("Error opening file");
        return EXIT_FAILURE;
    }

    yyin = inputFile;

    do  {
        if (yyparse() != 0) {
            break; 
        }
    }while(!feof(inputFile));
    fclose(inputFile);
    return EXIT_SUCCESS;
}
