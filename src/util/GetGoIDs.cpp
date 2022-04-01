#include <iostream>
#include <client.hpp>
#include <string>

int main(){
    boost::network::http::client client;
    boost::network::http::client::request request("https://URL");
    request << boost::network:header("Connection", "close");
    boost::network::http::client::response response = client.get(request);
    std::cout << body(response);
}
