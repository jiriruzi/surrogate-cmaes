function dot = tree2dot(fid, tree, varargin)
%TREE2DOT Convert a classification tree into dot format.
%   fid                   -- an output file handle
%   settings
%     InnerNodeFormat     -- inner node format (string)
%     LeafNodeFormat      -- leaf format (string)
%     LeftEdgeFormat      -- format of the edge to the left child (string)
%     RightEdgeFormat     -- format of the edge to the right child (string)
%     LeafProperties      -- properties of the leaf nodes (function string -> struct)
%     InnerNodeProperties -- properties of the inner nodes (function string -> struct)
%     LeftEdgeProperties  -- properties of the left edges (function int, int -> struct)
%     RightEdgeProperties -- properties of the right edges (function int, int -> struct)
%
%  Prints the tree into an open file fid.
%
%  Note that setting named *Properties are handles to functions that return
%  a structure of dot properties depending on given node / edge.
%
%  Following example demonstrates default TeX format for labels and custom
%  leaf properties, which depend on class stored in the leaf. Such a format
%  may be further exported to TeX by dot2tex program.
%
%  >> load ionospehere;
%  >> tc = fitctree(X, Y);
%  >> settings.LeafProperties = @meta_leaf_fmt;
%  >> f = fopen('tree.gv', 'w');
%  >> tree2dot(f, tc, settings);
%  >> fclose(f);
%
%  See also NODE2DOT, EDGE2DOT, META_LEAF_FMT

  settings = settings2struct(varargin{:});
  
  leaf_fmt = defopts(settings, 'LeafFormat', '\\\\texttt{%s}');
  leaf_lbl = @(cls) sprintf(leaf_fmt, cls);

  inner_node_fmt = defopts(settings, 'InnerNodeFormat', '\\\\feat{%s}');
  inner_node_lbl = @(feat) sprintf(inner_node_fmt, feat);

  left_edge_fmt = defopts(settings, 'LeftEdgeFormat', '$< %.2f$');
  left_edge_lbl = @(tr) sprintf(left_edge_fmt, tr);

  right_edge_fmt = defopts(settings, 'RightEdgeFormat', '$\\\\geq %.2f$');
  right_edge_lbl = @(tr) sprintf(right_edge_fmt, tr);

  left_edge_props = defopts(settings, 'LeftEdgeProperties', @(a, b) struct());
  right_edge_props = defopts(settings, 'RightEdgeProperties', @(a, b) struct());

  inner_node_props = defopts(settings, 'InnerNodeProperties', @(a) struct());
  leaf_props = defopts(settings, 'LeafProperties', ...
    @(a) struct('shape', 'box', 'fillcolor', 'LightPink', 'style', 'filled'));

  Leaves = ~tree.IsBranchNode;
  
  % header
  fprintf(fid, 'digraph {\n');
  fprintf(fid, '\tnode[label=""]\n');
  fprintf(fid, '\tedge[arrowhead=none]\n');

  for i = 1:tree.NumNodes
    children = find(tree.Parent == i);

    if Leaves(i)
      % leaf
      assert(numel(children) == 0);
      node2dot(fid, i, leaf_lbl(tree.NodeClass{i}), leaf_props(tree.NodeClass{i}));
    else
      % inner node
      assert(numel(children) == 2);

      node2dot(fid, i, inner_node_lbl(tree.CutPredictor{i}), inner_node_props(tree.CutPredictor{i}));

      % edges
      left = children(1);
      right = children(2);
      edge2dot(fid, i, left, left_edge_lbl(tree.CutPoint(i)), left_edge_props(i, left));
      edge2dot(fid, i, right, right_edge_lbl(tree.CutPoint(i)), right_edge_props(i, right));
    end
  end

  % footer
  fprintf(fid, '}\n');
end
