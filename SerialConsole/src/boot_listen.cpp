#include <boost/asio.hpp>
#include <iostream>
#include <exception>

// 1. Listen on boot until login prompt
// 2. Enable searhing for a specific pattern in the output

int main(void) {

	boost::asio::io_service io;
	boost::asio::serial_port ser_port(io);
	const std::string port = "/dev/ttyUSB0"; 
	const uint32_t baud_rate = 115200;
	ser_port.open(port);
	std::cout << "here1" << std::endl;
	ser_port.set_option(boost::asio::serial_port_base::baud_rate(baud_rate));
	std::cout << ser_port.is_open() << std::endl;

	boost::asio::streambuf buff;
	try {
		std::cout << ser_port.is_open() << std::endl;
		while (ser_port.is_open()) {
			std::cout << ser_port.is_open() << std::endl;

			boost::system::error_code error;
			// TODO: Figure out what is the delimiter of boot log!
			std::size_t n = boost::asio::read_until(ser_port, buff, "a", error);
			std::istream str(&buff);
			std::string s;
			std::getline(str, s);
			std::cout << "here" << std::endl;
		}

	} catch (const std::exception& e) {
		std::cout << e.what() << std::endl;
	}

	return 0;
}
