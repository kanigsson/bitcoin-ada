with Ada.Text_IO; use Ada.Text_IO;
with Block; use Block;
with Types; use Types;
procedure Main is
   Genesis_Block : constant String :=
     "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
   B : Block_Type;
begin
   B := Get_Block (Genesis_Block);
   Print_Block (B);
   Put_Line ("block hash = " & Uint_256_Hex (Block_Hash (B)));
end Main;
