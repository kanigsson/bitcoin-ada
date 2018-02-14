with Ada.Text_IO; use Ada.Text_IO;
with Block; use Block;
with Types; use Types;
procedure Main is
--     Genesis_Block : constant String :=
--       "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
   Cur : String :=
     "00000000000000000044e859a307b60d66ae586528fcc6d4df8a7c3eff132456";
   S : String (1 ..64);
   Count : Integer := 0;
begin
   loop
      declare
         B : constant Block_Type := Get_Block (Cur);
      begin
         S := Uint_256_Hex (Block_Hash (B));
         Put_Line ("checking block hash = " & S);
         Check_Block (B);
         exit when Count > 10;
         Count := Count + 1;
         --  Check_Block checks the block itself, but not that it has the
         --  expected hash, checking that here
         if not (Same_Hash (S,Cur)) then
            Ada.Text_IO.Put_Line ("found block hash mismatch");
         end if;
         exit when B.Header.Prev_Block = Uint_256_0;
         Cur := Uint_256_Hex (B.Header.Prev_Block);
      end;
   end loop;
end Main;
