Sequel.migration do
  up do
    create_table :things do
      primary_key :id
      String :name, :null => false, :unique => true
      Integer :dylans, :null => false

      constraint(:dylans_positive) { dylans > 0 }
      constraint(:dylans_max) { dylans < 4 }
    end
  end
end
