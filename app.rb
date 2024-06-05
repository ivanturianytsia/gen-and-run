require 'dotenv'
require 'openai'

class App
  TEST_CODE = <<-NODE_CODE
    const http = require('http');
    const url = require('url');
    
    const server = http.createServer((req, res) => {
      const reqUrl = url.parse(req.url, true);
      
      if (reqUrl.pathname === '/sum' && reqUrl.query.num1 && reqUrl.query.num2) {
        const num1 = parseInt(reqUrl.query.num1);
        const num2 = parseInt(reqUrl.query.num2);
        
        const sum = num1 + num2;
        
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end(`The sum of ${num1} and ${num2} is ${sum}`);
      } else {
        res.writeHead(404, {'Content-Type': 'text/plain'});
        res.end('Endpoint not found');
      }
    });
    
    server.listen(3000, () => {
      console.log('Server is running on port 3000');
    });
  NODE_CODE

  def initialize
    Dotenv.load

    client = OpenAI::Client.new(
      access_token: ENV['OPENAI_KEY'],
      log_errors: true
    )

    message = 'Write a web server in node.js that has one endpoint which sums 2 numbers and responds with a sum. Respond only with the runnable code.'

    response = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo-0125',
        messages: [{ role: 'user', content: message }],
        temperature: 0.7
      }
    )
    code = response.dig('choices', 0, 'message', 'content')

    code = code.gsub("'", '"')
    puts code

    pid = Process.spawn("node -e '#{code}'")

    sleep 5
    puts "Main thread about to kill the child thread"
    Process.kill('TERM', pid)
    puts "Child thread killed and joined"
  end
end

App.new
