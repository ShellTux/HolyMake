#include "factorial.hpp"

#include <cstddef>
#include <iostream>
#include <ostream>

int main()
{
	constexpr std::size_t number = 6;
	std::cout << number << "! = " << factorial(number) << std::endl;
	return 0;
}

std::size_t factorial(const std::size_t number)
{
	if (number <= 1) {
		return number;
	}

	return number * factorial(number - 1);
}
