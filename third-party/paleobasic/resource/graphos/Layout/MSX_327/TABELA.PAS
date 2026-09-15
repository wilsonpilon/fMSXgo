PROGRAM TABELA;
VAR
  I,J,K,M,N:INTEGER;
 BEGIN
     READLN(M,N);
     FOR I:= 1 TO M DO
   BEGIN
      WRITELN;
        FOR J:= 1 TO N DO
      BEGIN
          K:= J*I;
            WRITELN(J,'X',I,'=',K)
      END
   END
 END.
