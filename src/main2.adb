with Ada.Streams; use Ada.Streams;
with Ada.Unchecked_Conversion;
with Ada.Text_IO; use Ada.Text_IO;
with Rmd; use Rmd;
with Types; use Types;
with GNAT.SHA256; use GNAT.SHA256;

procedure Main2 is

   function Hash160 (X: Large_Number) return Uint_160;

   function Hash160 (X: Large_Number) return Uint_160 is
      S : String (1 .. X'Size / 8);
      for S'Address use X'Address;
      D : constant Binary_Message_Digest := Digest (S);
      --  create a new buffer of 64 bytes for input to RIPEMD160 hash
      D_Prime : Stream_Element_Array (1 .. 64);
   begin
      --  The Rmd library doesn't do padding, where the message is padded to
      --  match the block size of RIPEMD of 64 bytes. We need do to the padding
      --  ourselves here to extend the SHA256 hash (32 bytes) to the expected
      --  64 bytes. This is done by:
      --   - adding 1 bit at the end of the message
      --   - encoding length of the original message in the last 8 byte of the
      --     message, in little endian.
      --  source:
      --  https://crypto.stackexchange.com/questions/32400/how-does-ripemd160-pad-the-message

      --  copy the SHA256 hash at the beginning of the buffer
      D_Prime (1 .. 32) := D;
      --  set rest of buffer to zero ...
      D_Prime (33 .. 64) := (others => 0);
      --  ... but add a single bit set to '1' at the end ...
      D_Prime (33) := 16#80#;
      --  ... and encode the length of 8 * 32 = 256 bits starting at byte 57.
      --  In fact this means setting byte 58 to 1.
      D_Prime (58) := 1;
      declare
         M : Message (1 .. 1);
         For M'Address use D_Prime'Address;
         C : Chain := Hash (M);
         Z : Uint_160;
         for Z'Address use C'Address;
      begin
         return Z;
      end;
   end Hash160;

   Z : constant Large_Number := Large_Number_From_Hex
       ("ae53dcbaa13116a26f797d164050241884d07f8fd4f60db025ffbafbb9683044751402212c1aa9d5dc1dcca2cd75876254f4bb23383e180d0db1ce0d4c505eacd7c0ddee022115ca03e274c0dd344e1846527b107a9a525004946d25eeffcdae545848829c43022152");
   H : constant Uint_160 := Hash160 (Z);
begin
   Put_Line (Large_Number_Hex (H));
end Main2;
