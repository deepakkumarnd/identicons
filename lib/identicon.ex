defmodule Identicon do
  defmodule Image do
    defstruct hex: nil, color: nil, grid: nil
  end

  @moduledoc """
  Documentation for Identicon. Generates identicons from the word given as argument.
  """

  @doc """
  Generates identicons

  ## Examples

      iex> Identicon.generate("deepak")
      :ok

  """
  def generate(word) when is_binary(word) do
    word
    |> hash
    |> set_color
    |> generate_grid
    |> IO.inspect
    :ok
  end

  # Generates md5 hash and converts that hash to a list of 16 hexadecimal numbers.
  # An image struct is returned with the hex list.
  defp hash(word) do
    hex =
      :crypto.hash(:md5, word)
      |> :erlang.binary_to_list

    %Image{hex: hex}
  end

  # Color is set using the first three numbers from the hex list
  defp set_color(%Image{hex: [r, g, b | _tail]} = image) do
    %Image{image | color: [r, g, b]}
  end

  # Generates a 5x5 grid of numbers our of the hex list
  # The list [73, 139, 89, 36, 173, 196, 105, 170, 123, 102, 15, 69, 126, 15, 199, 229]
  # will get converted to
  # [
  #   [73, 139, 89, 139, 73],
  #   [36, 173, 196, 173, 36],
  #   [105, 170, 123, 170, 105],
  #   [102, 15, 69, 15, 102],
  #   [126, 15, 199, 15, 126]
  # ]
  # This grid will be further converted to
  # [
  #   [0, 0, 0, 0, 0],
  #   [1, 0, 1, 0, 1],
  #   [0, 1, 0, 1, 0],
  #   [1, 0, 0, 0, 1],
  #   [1, 0, 0, 0, 1]
  # ]
  # Here 0 means we don't color the cell and 1 means we will color the cell.
  # In the implimentation we have't generated the first grid, instead we are
  # directly generating the second grid.
  #
  # The generated binary grid is then flattened and index is generated for each
  # entry in the final list, the final grid will look like this.
  # [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}, {1, 5}, ..]
  defp generate_grid(%Image{hex: hex} = image) do
    grid = hex
      |> Enum.map(fn(code) -> if rem(code, 2) == 0, do: 1, else: 0 end)
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_rows/1)
      |> List.flatten
      |> Enum.with_index

    %Image{image | grid: grid}
  end

  defp mirror_rows([first, second | _tail] = row) do
    row ++ [second, first]
  end
end
