# DevOps
DevOps Exercises
Step-by-Step Process:

1.Client Request to Access devops.com
A client initiates a request to access the website devops.com by entering the URL in their browser or through another application.
The browser first needs to resolve the domain name devops.com into an IP address. For this purpose, it sends a DNS query to the configured DNS resolver.
2.DNS Resolution
The DNS server associated with devops.com has two IP addresses registered for the domain. These IP addresses correspond to the load balancers that manage traffic for the website.
To distribute traffic evenly, the DNS server uses the Round Robin method to return one of the two IP addresses.
In this instance, the DNS server returns the first IP address, which is the virtual IP (VIP) of the primary load balancer configured using the VRRP (Virtual Router Redundancy Protocol).

3.Client Traffic to the Load Balancer
The client sends its request to the IP address provided by DNS. This address belongs to the primary load balancer, which is designated as the master in the VRRP configuration.
The load balancer receives the client's HTTPS request for https://devops.com.
4.Load Balancer Handling the Request
Based on its configuration, the load balancer decides which backend web server will handle the client’s request. This decision might be based on algorithms like Round Robin, Least Connections, or Weighted Distribution.
The selected web server's IP address is retrieved, and the request is forwarded.
5.Protocol Translation (HTTPS to HTTP)
The client's traffic from the client to the load balancer is secured using HTTPS (encrypted communication).
Once the load balancer processes the request, it forwards it to the backend web server using HTTP (unencrypted communication). This configuration helps offload the SSL/TLS encryption process from the web servers to the load balancer.
6.Web Server Response
The web server processes the request and generates a response (e.g., the requested webpage or data).
The response is sent back to the load balancer over HTTP.
7.Response to the Client
The load balancer receives the response from the web server.
Before sending the response back to the client, the load balancer re-encrypts the communication using HTTPS to maintain security.
Finally, the response is delivered to the client, and the website content (e.g., devops.com) is displayed in the browser.
