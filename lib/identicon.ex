defmodule Identicon do
  defmodule Image do
    defstruct hex: nil, color: nil, grid: nil, pixel_map: nil
  end

  @moduledoc """
  Documentation for Identicon. Generates identicons from the word given as argument.
  """

  @doc """
  Generates identicons

  ## Examples

      iex> Identicon.generate("hello")
      :ok

  """
  def generate(word) when is_binary(word) do
    word
    |> hash
    |> set_color
    |> generate_grid
    |> generate_pixel_map
    |> generate_image
    |> save_image(word)
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
    %Image{image | color: {r, g, b}}
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
  # entry in the final list, the final grid will look like this. The final list contains
  # those indexes which need to be colored.
  # [ {1, 5}, {1, 7}, {1, 9}, {1, 11}, {1, 13}, {1, 15}, {1, 19}, {1, 20}, {1, 24}]
  defp generate_grid(%Image{hex: hex} = image) do
    grid = hex
      |> Enum.map(fn(code) -> if rem(code, 2) == 0, do: 1, else: 0 end)
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_rows/1)
      |> List.flatten
      |> Enum.with_index
      |> Enum.filter(fn({code, _index}) -> code == 1 end)

    %Image{image | grid: grid}
  end

  defp mirror_rows([first, second | _tail] = row) do
    row ++ [second, first]
  end

  # The generated image will be of size 250 x 250 and will have 25 squares of size 50 x 50.
  defp generate_pixel_map(%Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_, index}) ->
      x = rem(index, 5) * 50
      y = div(index, 5) * 50
      top_left     = {x, y}
      bottom_right = {x + 50, y + 50}
      {top_left, bottom_right}
    end

    %Image{image | pixel_map: pixel_map}
  end

  # Here the :egd.filledRectangle function can modify the image object which is not common in
  # elixir world, but this is one of an exception where the object is modified by a function.
  defp generate_image(%Image{pixel_map: pixel_map, color: color}) do
    image = :egd.create(250, 250)
    fill  = :egd.color(color)
    Enum.each pixel_map, fn({top_left, bottom_right}) ->
      :egd.filledRectangle(image, top_left, bottom_right, fill)
    end

    :egd.render(image)
  end

  defp save_image(buffer, filename) do
    File.write("#{filename}.png", buffer)
  end
end
