with Ada.Text_IO; use Ada.Text_IO;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;
with Ada.Unchecked_Conversion;
with GNAT.SHA256; use GNAT.SHA256;
with GNAT.Expect; use GNAT.Expect;
with GNATCOLL.JSON; use GNATCOLL.JSON;

package body Block is

   Msg_Start : constant Interfaces.Unsigned_32 := 16#f9beb4d9#;

   subtype Two_Char is String (1 .. 2);

   procedure Uint_8_Hex (S : out Two_Char; X : Unsigned_8) is
      package Unsigned_8_IO is new Ada.Text_IO.Modular_IO (Unsigned_8);

      Tmp : String (1 .. 6);
   begin
      Unsigned_8_IO.Put (To => Tmp, Item => X, Base => 16);
      if X < 16 then
         S (1) := '0';
         S (2) := Tmp (5);
      else
         S := Tmp (4 .. 5);
      end if;
   end Uint_8_Hex;

   subtype String_8 is String (1 ..8);
   function Uint32_from_Hex (S : String_8) return Unsigned_32 is
   begin
      return Unsigned_32'Value
        ("16#" & S & "#");
   end Uint32_from_Hex;

   function Uint_32_Hex (X : Unsigned_32) return String is
      package Unsigned_32_IO is new Ada.Text_IO.Modular_IO (Unsigned_32);

      Tmp : String (1 .. 12);
      Lead_Zeros : Natural := 0;
   begin
      Unsigned_32_IO.Put (To => Tmp, Item => X, Base => 16);
      -- count spaces at beginning of string to know how many 0 to add later
      for I in Tmp'Range loop
         exit when Tmp (I) /= ' ';
         Lead_Zeros := Lead_Zeros + 1;
      end loop;
      return String'(1 .. Lead_Zeros => '0') & Tmp (Lead_Zeros + 4 .. 11);
   end Uint_32_Hex;

   function Uint_8_from_Hex (S : String) return Unsigned_8 is
   begin
      return Unsigned_8'Value ("16#" & S & "#");
   end Uint_8_from_Hex;

   function Uint256_from_Hex (S : String) return Uint_256 is
      B : Uint_256;
   begin
      for I in B'Range loop
         B (I) := Uint_8_from_Hex (S (64 - 2 * (I -1) - 1 .. 64 - 2 * (I - 1)));
      end loop;
      return B;
   end Uint256_from_Hex;

   function Uint_256_Hex (U : Uint_256) return String is
      Result : String (1 ..64);
   begin
      for I in U'Range loop
         Uint_8_Hex (Result (64 - 2 * (I - 1) - 1 .. 64 - 2 * (I - 1)), U (I));
      end loop;
      return Result;
   end Uint_256_Hex;

   procedure Print_Block (B : Block_Type) is
   begin
      Put_Line ("Version = " & Unsigned_32'Image (B.Version));
      Put_Line ("Prev_Block = " & Uint_256_Hex (B.Prev_Block));
      Put_Line ("Merkle_Root = " & Uint_256_Hex (B.Merkle_Root));
      Put_Line ("Timestamp = " & Unsigned_32'Image (B.Timestamp));
      Put_Line ("Size = " & Uint_32_Hex (B.Bits));
      Put_Line ("Nonce = " & Unsigned_32'Image (B.Nonce));
   end Print_Block;

   function Get_Block (Hash : String) return Block_Type is
      Status : aliased Integer;
      B : Block_Type;
      J : Json_Value;
   begin
      J := Read
        (Get_Command_Output (Command => "/seoul.a/play/bitcoin/bin/bitcoin-cli",
                             Arguments => (1 => new String'("getblock"),
                                           2 => new String'(Hash)),
                             Input => "",
                             Status => Status'Access,
                             Err_To_Out => True));
      B.Version := Unsigned_32 (Integer'(Get (Get (J, "version"))));
      B.Bits := Uint32_from_Hex (Get (Get (J, "bits")));
      B.Nonce := Unsigned_32 (Integer'(Get (Get (J, "nonce"))));
      B.Timestamp := Unsigned_32 (Integer'(Get (Get (J, "time"))));
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
      D2 : Binary_Message_Digest := Digest (T);

      function To_Uint_256 is new Ada.Unchecked_Conversion
        (Source => Binary_Message_Digest,
         Target => Uint_256);

   begin
      return To_Uint_256 (D2);
   end Block_Hash;

end Block;
