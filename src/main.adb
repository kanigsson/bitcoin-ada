with Block; use Block;
procedure Main is
   Block_File : constant String :=
     "/seoul.a/play/bitcoin/blockchain/blocks/blk00000.dat";
begin
   Read_Blocks (Block_File);
end Main;
