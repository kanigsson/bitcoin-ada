with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Expect; use GNAT.Expect;
with GNATCOLL.JSON; use GNATCOLL.JSON;

package body Block is

   function Merkle_Computation (Tx : Transaction_Array) return Uint_256;
   --  compute the merkle root of the merkle tree whose leafs are the hashes in
   --  the argument array

   function SHA256Pair (U1, U2 : Uint_256) return Uint_256;

   ----------------
   -- Block_Hash --
   ----------------

   function Block_Hash (B : Block_Type) return Uint_256 is
      S : String (1 .. Block_Header'Size / 8);
      for S'Address use B.Header'Address;
   begin
      return Double_Hash (S);
   end Block_Hash;

   -----------------
   -- Check_Block --
   -----------------

   procedure Check_Block (B : Block_Type) is
   begin
      if B.Header.Merkle_Root /= Merkle_Computation (B.Transactions) then
         Ada.Text_IO.Put_Line ("found Merkle root mismatch");
      end if;
   end Check_Block;

   ---------------
   -- Get_Block --
   ---------------

   function Get_Block (Hash : String) return Block_Type is
      Status : aliased Integer;
      J : Json_Value;
   begin
      J := Read
        (Get_Command_Output (Command => "bitcoin-cli",
                             Arguments => (1 => new String'("getblock"),
                                           2 => new String'(Hash)),
                             Input => "",
                             Status => Status'Access,
                             Err_To_Out => True));
      declare
         Tx : constant JSON_Array := Get (J, "tx");
         B : Block_Type (Length (Tx));
      begin
         B.Header.Version := Uint_32 (Integer'(Get (Get (J, "version"))));
         B.Header.Bits := Uint_32_from_Hex (Get (Get (J, "bits")));
         B.Header.Nonce := Uint_32 (Long_Integer'(Get (Get (J, "nonce"))));
         B.Header.Timestamp := Uint_32 (Integer'(Get (Get (J, "time"))));
         if Has_Field (J, "previousblockhash") then
            B.Header.Prev_Block :=
              Uint256_From_Hex (Get (Get (J, "previousblockhash")));
         else
            B.Header.Prev_Block := Uint_256_0;
         end if;
         B.Header.Merkle_Root :=
           Uint256_from_Hex (Get (Get (J, "merkleroot")));
         for I in 1 .. B.Num_Transactions loop
            B.Transactions (I) :=
              Uint256_from_Hex (Get (Get (Tx, I)));
         end loop;
         return B;
      end;
   end Get_Block;

   ------------------------
   -- Merkle_Computation --
   ------------------------

   function Merkle_Computation (Tx : Transaction_Array) return Uint_256 is
      Max : Integer :=
          (if Tx'Length rem 2 = 0 then Tx'Length else Tx'Length + 1);
      Copy : Transaction_Array (1 .. Max);
   begin
      if Tx'Length = 1 then
         return Tx (Tx'First);
      end if;
      if Tx'Length = 0 then
         raise Program_Error;
      end if;
      Copy (1 .. Tx'Length) := Tx;
      if (Max /= Tx'Length) then
         Copy (Max) := Tx (Tx'Last);
      end if;
      loop
         for I in 1 .. Max / 2 loop
            Copy (I) := SHA256Pair (Copy (2 * I - 1), Copy (2 *I ));
         end loop;
         if Max = 2 then
            return Copy (1);
         end if;
         Max := Max / 2;
         if Max rem 2 /= 0 then
            Copy (Max + 1) := Copy (Max);
            Max := Max + 1;
         end if;
      end loop;
   end Merkle_Computation;

   -----------------
   -- Print_Block --
   -----------------

   procedure Print_Block (B : Block_Type) is
   begin
      Put_Line ("Version = " & Uint_32'Image (B.Header.Version));
      Put_Line ("Prev_Block = " & Uint_256_Hex (B.Header.Prev_Block));
      Put_Line ("Merkle_Root = " & Uint_256_Hex (B.Header.Merkle_Root));
      Put_Line ("Timestamp = " & Uint_32'Image (B.Header.Timestamp));
      Put_Line ("Size = " & Uint_32_Hex (B.Header.Bits));
      Put_Line ("Nonce = " & Uint_32'Image (B.Header.Nonce));
   end Print_Block;

   ----------------
   -- SHA256Pair --
   ----------------

   function SHA256Pair (U1, U2 : Uint_256) return Uint_256 is
      type A is array (1 .. 2) of Uint_256;
      X : A := (U1, U2);
      S : String (1 .. X'Size / 8);
      for S'Address use X'Address;
   begin
      return Double_Hash (S);
   end SHA256Pair;

end Block;
