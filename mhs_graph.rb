require 'rubygems'
require 'graphviz'

$max = 7
$MAX_TRIAL = 10000

class Integer
  def to_b
    s = ""
    v = self
    $max.times{|i|
      s = (v&1).to_s + s
      v = v >> 1
    }
    s
  end

  def to_a
    v = self
    r = []
    $max.times do |i|
      if (1<<($max-i-1)) & v !=0
        r.push ($max-i)
      end
    end
    r
  end
end

class Array
  def show
    self.each do |v|
      puts v.to_b
    end
  end
end


class ConnectChecker
  class << self
  def check(size,a)
    @size = size
    @cluster = Array.new(@size){|i| i}
    a.each do |v|
      (i,j) = v.to_a
      connect(i-1,j-1)
    end
    @size.times do |i|
      return false if get_cluster_index(i)!=0
    end
    true
  end
  def connect(i,j)
    i1 = get_cluster_index(i)
    j1 = get_cluster_index(j)
    if i1 < j1
      @cluster[j1] = i1
    else
      @cluster[i1] = j1
    end
  end
  def get_cluster_index(i)
    while @cluster[i] !=i
      i = @cluster[i]
    end
    i
  end
  end
end

class MHSFinder
  class << self
    def search(k, t, e, r)
      if k == e.size
        r.push t
        return
      end
      if (t & e[k]) !=0
        search(k+1,t,e,r)
        return
      end
      v = e[k]
      while v!=0
        t2 = v & -v
        if check_minimal(t|t2,k+1,e)
          search(k + 1, t | t2, e,r)
        end
        v = v ^ t2
      end
    end
    def check_minimal(t,k,e)
      v = t
      while v!=0
        t2 = v & -v
        t3 = t ^ t2
        if e.slice(0..(k-1)).collect{|ei| (ei & t3)!=0}.inject(:&)
          return false
        end
        v = v ^ t2
      end
      return true
    end
    def find(e)
      r = []
      search(0,0,e,r)
      r
    end
  end
end


def make_input_sub(n)
  t = 0
  tmax = (1 << $max) -1
  a = Array.new($max){|i| i+1}
  b = a.combination(2).to_a.shuffle
  r = []
  b.each do |x,y|
    te = (1 << (x-1)) | (1 << (y-1))
    r.push te
    t = t | te
    break if t == tmax
  end
  r
end

def make_input(n)
  $max = n
  $MAX_TRIAL.times do
    a = make_input_sub(n)
    return a if ConnectChecker.check(n,a)
  end
  warn("Could not make sample.")
  exit(-1)
end

def save_graph(filename, a)
  GraphViz::new("G",{:type =>"graph"}) do |g|
    n = []
    $max.times do |i|
      n.push g.add_node((i+1).to_s)
    end
    a.size.times do |i|
      n1,n2 = a[i].to_a
      e = g.add_edge(n[n1-1],n[n2-1])
      e[:label => ('A'.ord+i).chr]
    end
  end.output(:png => filename)
  puts "Saved as #{filename}"
end

def save_graph_with_mhs(basename, a, r)
  index = 0
  r.each do |ri|
    filename = basename + index.to_s + ".png"
    index = index + 1
    GraphViz::new("G",{:type =>"graph"}) do |g|
      n = []
      $max.times do |i|
        n.push g.add_node((i+1).to_s)
      end
      a.size.times do |i|
        n1,n2 = a[i].to_a
        e = g.add_edge(n[n1-1],n[n2-1])
        e[:label => ('A'.ord+i).chr]
      end
      ri.to_a.each do |rii|
        n[rii-1][:color => "red", :style => "filled"]
      end
    end.output(:png => filename)
    puts "Saved as #{filename}"
  end
end

def save_as_dat(filename,a)
  puts "Saved as #{filename}"
  open(filename,"w") do |f|
    a.each do |ai|
      f.puts ai.to_a.join(",")
    end
  end
end

def save_as_bit(filename,a)
  puts "Saved as #{filename}"
  open(filename,"w") do |f|
    a.each do |ai|
      f.puts ai.to_b
    end
  end
end

def show_condition(a)
  h = Array.new(a.size)
  a.size.times do |i|
    h[i] = Hash.new
    (x,y) = a[i].to_a
    h[i][x-1] = 1
    h[i][y-1] = 1
  end
  print "|   |"
  a.size.times do |j|
    print " #{('A'.ord + j).chr} |"
  end
  puts
  print "|---|"
  a.size.times do |j|
    print "---|"
  end
  puts
  $max.times do |i|
    print "| #{i+1} |"
    a.size.times do |j|
      if h[j].has_key?(i)
        print " O |"
      else
        print " - |"
      end
    end
    puts
  end
end

def main(size=5, seed=-1)
  srand(seed) if seed >=0
  a = make_input(size)
  puts
  puts "Input Condition"
  show_condition(a)
  puts
  puts "Minimal Hitting Sets"
  r = MHSFinder.find(a)
  r.each do |ri|
    puts ri.to_a.join(",")
  end
  puts
  save_as_dat("input.dat",a)
  save_as_bit("input.bit",a)
  save_as_dat("mhs.dat",r)
  save_as_bit("mhs.bit",r)
  save_graph("graph.png",a)
  save_graph_with_mhs("graph_mhs",a,r) 
end

size = 5
seed = -1

if ARGV.size > 0
  size = ARGV[0].to_i
end

if ARGV.size > 1
  seed = ARGV[1].to_i
end

main(size,seed)
