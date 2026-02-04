#include "pch.h"
#include "TcpServerSocket.h"
#include "TcpServerSocketManager.h"

#include <spdlog/spdlog.h>

TcpServerSocket::TcpServerSocket(test_tag tag) : TcpSocket(tag)
{
}

TcpServerSocket::TcpServerSocket(TcpServerSocketManager* socketManager) : TcpSocket(socketManager)
{
}

std::string_view TcpServerSocket::GetImplName() const
{
	return "TcpServerSocket";
}

void TcpServerSocket::Initialize()
{
	if (_socket == nullptr || !_socket->is_open())
		return;

	asio::error_code ec;

	// Enable TCP_NODELAY to disable Nagle's algorithm
	// This prevents delayed ACKs which can cause connection issues in Docker
	_socket->set_option(asio::ip::tcp::no_delay(true), ec);
	if (ec)
	{
		spdlog::warn("TcpServerSocket::Initialize: failed to set TCP_NODELAY option. [socketId={} "
					 "error={}]",
			_socketId, ec.message());
	}

	// Enable SO_KEEPALIVE to maintain connections and detect disconnected clients
	// This is critical in Docker environments where network bridges may close idle connections
	_socket->set_option(asio::socket_base::keep_alive(true), ec);
	if (ec)
	{
		spdlog::warn("TcpServerSocket::Initialize: failed to set SO_KEEPALIVE option. [socketId={} "
					 "error={}]",
			_socketId, ec.message());
	}

	// Disable linger (close socket immediately regardless of existence of pending data)
	_socket->set_option(asio::socket_base::linger(false, 0), ec);
	if (ec)
	{
		spdlog::warn(
			"TcpServerSocket::Initialize: failed to set SO_LINGER option. [socketId={} error={}]",
			_socketId, ec.message());
	}

	// Configure receive buffer size
	// Uses 4x multiplier to match TcpClientSocket and acceptor configuration
	_socket->set_option(asio::socket_base::receive_buffer_size(_recvBufferSize * 4), ec);
	if (ec)
	{
		spdlog::warn("TcpServerSocket::Initialize: failed to set receive buffer size. [socketId={} "
					 "error={}]",
			_socketId, ec.message());
	}

	// Configure send buffer size
	// Uses 4x multiplier to match TcpClientSocket and acceptor configuration
	_socket->set_option(asio::socket_base::send_buffer_size(_sendBufferSize * 4), ec);
	if (ec)
	{
		spdlog::warn(
			"TcpServerSocket::Initialize: failed to set send buffer size. [socketId={} error={}]",
			_socketId, ec.message());
	}
}
