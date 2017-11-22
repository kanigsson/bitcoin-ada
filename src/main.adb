with Ada.Text_IO; use Ada.Text_IO;
with Block; use Block;
procedure Main is
   Block_File : constant String :=
     "/seoul.a/play/bitcoin/blockchain/blocks/blk00000.dat";
   B : Block_Type;
begin
   B := Read_Block (Block_File);
   Print_Block (B);
   Put_Line ("block hash = " & Uint_256_Hex (Block_Hash (B)));
end Main;
