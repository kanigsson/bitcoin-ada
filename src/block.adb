with Ada.Text_IO; use Ada.Text_IO;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;

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

   function Uint_256_Hex (U : Uint_256) return String is
      Result : String (1 ..64);
   begin
      for I in U'Range loop
         Uint_8_Hex (Result (2 * (I - 1) + 1 .. 2 * I), U (I));
      end loop;
      return Result;
   end Uint_256_Hex;

   procedure Print_Block (B : Block) is
   begin
      Put_Line ("Version = " & Unsigned_32'Image (B.Version));
      Put_Line ("Prev_Block = " & Uint_256_Hex (B.Prev_Block));
      Put_Line ("Merkle_Root = " & Uint_256_Hex (B.Merkle_Root));
      Put_Line ("Timestamp = " & Unsigned_32'Image (B.Timestamp));
      Put_Line ("Size = " & Uint_32_Hex (B.Size));
      Put_Line ("Nonce = " & Unsigned_32'Image (B.Nonce));
   end Print_Block;

   procedure Read_Blocks (File : String) is
      Handle : File_Type;
      Tmp : Interfaces.Unsigned_32;
      B : Block;
   begin
      Open (Handle, In_File, File);
      --  read block header marker and check it's really a block header marker
      Unsigned_32'Read (Stream (Handle), Tmp);
      pragma Assert (Tmp = Msg_Start);
      --  ??? skip 32bit of unknown use
      Unsigned_32'Read (Stream (Handle), Tmp);
      -- read block header
      Unsigned_32'Read (Stream (Handle), B.Version);
      Uint_256'Read (Stream (Handle), B.Prev_Block);
      Uint_256'Read (Stream (Handle), B.Merkle_Root);
      Unsigned_32'Read (Stream (Handle), B.Timestamp);
      Unsigned_32'Read (Stream (Handle), B.Size);
      Unsigned_32'Read (Stream (Handle), B.Nonce);
      Print_Block (B);
   end Read_Blocks;

end Block;
