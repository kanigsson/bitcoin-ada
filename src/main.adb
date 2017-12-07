with Ada.Text_IO; use Ada.Text_IO;
with Block; use Block;
with Types; use Types;
procedure Main is
--     Genesis_Block : constant String :=
--       "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
   Cur : String :=
     "00000000000000000044e859a307b60d66ae586528fcc6d4df8a7c3eff132456";
   B : Block_Type;
   S : String (1 ..64);
   C : Integer := 0;
begin
   loop
      B := Get_Block (Cur);
      S := Uint_256_Hex (Block_Hash (B));
      C := C + 1;
      if C mod 100 = 0 then
         Put_Line ("checking block hash = " & S);
      end if;
      pragma Assert (Same_Hash (S,Cur));
      exit when B.Prev_Block = Uint_256_0;
      Cur := Uint_256_Hex (B.Prev_Block);
   end loop;
end Main;
