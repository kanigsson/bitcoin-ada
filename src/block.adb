with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with GNAT.SHA256; use GNAT.SHA256;
with GNAT.Expect; use GNAT.Expect;
with GNATCOLL.JSON; use GNATCOLL.JSON;

package body Block is

   procedure Print_Block (B : Block_Type) is
   begin
      Put_Line ("Version = " & Uint_32'Image (B.Version));
      Put_Line ("Prev_Block = " & Uint_256_Hex (B.Prev_Block));
      Put_Line ("Merkle_Root = " & Uint_256_Hex (B.Merkle_Root));
      Put_Line ("Timestamp = " & Uint_32'Image (B.Timestamp));
      Put_Line ("Size = " & Uint_32_Hex (B.Bits));
      Put_Line ("Nonce = " & Uint_32'Image (B.Nonce));
   end Print_Block;

   function Get_Block (Hash : String) return Block_Type is
      Status : aliased Integer;
      B : Block_Type;
      J : Json_Value;
   begin
      J := Read
        (Get_Command_Output (Command => "/seoul.a/play/bitcoin/bin/bitcoin-cli",
                             Arguments => (1 => new String'("getblockheader"),
                                           2 => new String'(Hash)),
                             Input => "",
                             Status => Status'Access,
                             Err_To_Out => True));
      B.Version := Uint_32 (Integer'(Get (Get (J, "version"))));
      B.Bits := Uint_32_from_Hex (Get (Get (J, "bits")));
      B.Nonce := Uint_32 (Long_Integer'(Get (Get (J, "nonce"))));
      B.Timestamp := Uint_32 (Integer'(Get (Get (J, "time"))));
      if Has_Field (J, "previousblockhash") then
         B.Prev_Block := Uint256_From_Hex (Get (Get (J, "previousblockhash")));
      else
         B.Prev_Block := Uint_256_0;
      end if;
      B.Merkle_Root := Uint256_from_Hex (Get (Get (J, "merkleroot")));
      return B;
   end Get_Block;

   function Block_Hash (B : Block_Type) return Uint_256 is
      S : String (1 .. Block_Type'Size / 8);
      for S'Address use B'Address;
      D : Binary_Message_Digest := Digest (S);
      T : String (1 .. 32);
      for T'Address use D'Address;
      D2 : constant Binary_Message_Digest := Digest (T);

      function To_Uint_256 is new Ada.Unchecked_Conversion
        (Source => Binary_Message_Digest,
         Target => Uint_256);

   begin
      return To_Uint_256 (D2);
   end Block_Hash;

end Block;
