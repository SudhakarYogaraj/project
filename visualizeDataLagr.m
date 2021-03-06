% Write output files in VTK- or Tecplot-format.

%===============================================================================
%> @file visualizeDataLagr.m
%>
%> @brief Write output files in VTK- or Tecplot-format.
%===============================================================================
%>
%> @brief Write output files in VTK- or Tecplot-format.
%>
%> Depending on the given <code>fileTypes</code> (<code>'vtk'</code> (default) or
%> <code>'tec'</code>), it writes a <code>.vtu</code> or <code>.plt</code> file
%> for the visualization of a discrete quantity in 
%> @f$\mathbb{P}_p(\mathcal{T}_h), p \in \{0, 1, 2\}@f$.
%> Multiple file types can be given at the same time, see the example
%> below.
%>
%> Multiple data sets can be written to a single file. To do so, specify
%> the different data sets as a cell array. Additionally, multiple data
%> sets can be grouped into a vector and written as such (VTK only).
%>
%> The name of the generated file ist <code>fileName.tLvl.vtu</code> or
%> <code>fileName.tLvl.plt</code>, respectively, where <code>tLvl</code> stands
%> for time level.
%>
%> @note Although the VTK-format supports @f$p=2@f$, Paraview (4.2.0 at the time
%>       of writing) splits each triangle into four triangles and visualizes
%>       the function as piecewise linear.
%>
%> @note The Tecplot file format doesn't support higher order functions, 
%>       therefore each triangle is split into four triangles with linear
%>       representation.
%>
%> @par Example
%> @parblock
%> @code
%> g = generateGridData([0, -1; sqrt(3), 0; 0, 1; -sqrt(3), 0], [4,1,3; 1,2,3]);
%> g.idE = (abs(g.nuE(:,2)) > 0) .* ((g.nuE(:,1)>0) + (g.nuE(:,2)>0)*2+1);
%> fAlg = @(X1, X2) (X1<0).*(X1.^2 - X2.^2 - 1) + (X1>=0).*(-X1.^2 - X2.^2 + 1);
%> for N = [1, 3, 6]
%>   p = (sqrt(8*N+1)-3)/2;
%>   quadOrd = max(2*p, 1);
%>   computeBasesOnQuad(N);
%>   fDisc = projectFuncCont2DataDisc(g, fAlg, quadOrd, integrateRefElemPhiPhi(N));
%>   fLagr = projectDataDisc2DataLagr(fDisc);
%>   visualizeDataLagr(g, fLagr, 'funname', ['fDOF', int2str(N)], 1, cellstr(['vtk';'tec']));
%> end
%> @endcode
%> produces the following output using Paraview:
%> @image html  visP0.png  "fDOF1.1.vtu with range [-2/3,1/3]" width=1cm
%> @image html  visP1.png  "fDOF3.1.vtu with range [-8/5,6/5]" width=1cm
%> @image html  visP2.png  "fDOF6.1.vtu with range [-2, 2]" width=1cm
%> @endparblock
%>
%> @par Example
%> @parblock
%> Assume a grid, <code>g</code>, and a cell array with discontinuous data,
%> <code>cDisc</code>, exist already.
%>
%> Then, the following code writes a single output file with a scalar field
%> for 'h' and a vector field 'velocity' with components 'u' and 'v'.
%> @code
%> varName = { 'h', 'u', 'v' }
%> vecName = struct('velocity', {{'u','v'}})
%> dataLagr = { projectDataDisc2DataLagr(cDisc{1}), ...
%>              projectDataDisc2DataLagr(cDisc{2}), ...
%>              projectDataDisc2DataLagr(cDisc{3}) };
%> visualizeDataLagr(g, dataLagr, varName, 'solution', 1, {'vtk', 'tec'}), vecName);
%> end
%> @endcode
%> @endparblock
%>
%> @param  g          The lists describing the geometric and topological 
%>                    properties of a triangulation (see 
%>                    <code>generateGridData()</code>) 
%>                    @f$[1 \times 1 \text{ struct}]@f$
%> @param  dataLagr   The Lagrangian representation of the quantity, as produced
%>                    by <code>projectDataDisc2DataLagr</code> @f$[K \times N]@f$.
%>                    Can be a cell array with multiple data sets.
%> @param  varName    The name of the quantity within the output file
%>                    If multiple data sets are given, this must be a cell
%>                    array with the same dimension as dataLagr, holding
%>                    the names of each data set.
%> @param  fileName   The basename of the output file
%> @param  tLvl       The time level
%> @param  fileTypes  (optional) The output format to be written 
%>                    (<code>'vtk'</code> (default) or <code>'tec'</code>).
%> @param  vecName    (optional) A struct that allows to define vectorial
%>                    output (for VTK only). Field names provide the vector
%>                    names and field values are cell arrays with variable
%>                    names.
%>
%>
%> This file is part of FESTUNG
%>
%> @copyright 2014-2015 Florian Frank, Balthasar Reuter, Vadym Aizinger
%> 
%> @par License
%> @parblock
%> This program is free software: you can redistribute it and/or modify
%> it under the terms of the GNU General Public License as published by
%> the Free Software Foundation, either version 3 of the License, or
%> (at your option) any later version.
%>
%> This program is distributed in the hope that it will be useful,
%> but WITHOUT ANY WARRANTY; without even the implied warranty of
%> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%> GNU General Public License for more details.
%>
%> You should have received a copy of the GNU General Public License
%> along with this program.  If not, see <http://www.gnu.org/licenses/>.
%> @endparblock
%
function visualizeDataLagr(g, dataLagr, varName, fileName, tLvl, fileTypes, vecName)
%% Deduce default arguments
if nargin < 6 || isempty(fileTypes)
  fileTypes = 'vtk';
end % if
if nargin < 7
  vecName = struct;
end % if
if ~iscell(dataLagr)
  dataLagr = { dataLagr };
end % if
if ~iscell(varName)
  varName = { varName };
end % if
if ~iscell(fileTypes)
  fileTypes = cellstr(fileTypes);
end % if
if size(fileTypes,1) > size(fileTypes,2)
  fileTypes = transpose(fileTypes);
end % if
%% Check function arguments
assert(isequal(size(dataLagr), size(varName)), 'Number of data sets in dataLagr does not match varName')
assert(all(cellfun(@(c) size(c, 1), dataLagr) == g.numT), 'Wrong number of elements in dataLagr')
assert(all(cellfun(@(c) size(c, 2), dataLagr) == size(dataLagr{1}, 2)), 'All data sets in dataLagr must have same approximation order')
%% Ensure target directory exists
[dirName,~,~] = fileparts(fileName);
if ~isempty(dirName) && ~isdir(dirName)
  mkdir(dirName);
end % if
%% Call correct function for writing file.
for fileType = fileTypes
  if strcmp(fileType, 'vtk')
    visualizeDataLagrVtk(g, dataLagr, varName, fileName, tLvl, vecName);
  elseif strcmp(fileType, 'tec')
    visualizeDataLagrTec(g, dataLagr, varName, fileName, tLvl);
  else
    error('Unknown file type: %s', fileType);
  end % if
end
end % function
%
%> @brief Helper routine to write VTK-files.
function visualizeDataLagrVtk(g, dataLagr, varName, fileName, tLvl, vecName)
[K, N] = size(dataLagr{1});
vecNames = fieldnames(vecName);
isVec = ~isempty(vecNames);
maskVec = false(size(varName));
for i = 1 : length(vecNames)
  maskVec = maskVec | ismember(varName, vecName.(vecNames{i}));
end % for
isScalar = ~all(maskVec);
%% Open file.
fileName = [fileName, '.', num2str(tLvl), '.vtu'];
file     = fopen(fileName, 'wt'); % if this file exists, then overwrite
%% Header.
fprintf(file, '<?xml version="1.0"?>\n');
fprintf(file, '<VTKFile type="UnstructuredGrid" version="0.1" byte_order="LittleEndian" compressor="vtkZLibDataCompressor">\n');
fprintf(file, '  <UnstructuredGrid>\n');
%% Points and cells.
switch N
  case {1, 3}
    P1          = reshape(g.coordV0T(:, :, 1)', 3*K, 1);
    P2          = reshape(g.coordV0T(:, :, 2)', 3*K, 1);
    numP        = 3; % number of local points
    id          = 5; % vtk ID for linear polynomials
  case 6
    P1          = reshape([g.coordV0T(:,:,1), g.baryE0T(:,[3,1,2],1)]',6*K,1);
    P2          = reshape([g.coordV0T(:,:,2), g.baryE0T(:,[3,1,2],2)]',6*K,1);
    numP        = 6; % number of local points
    id          = 22; % vtk ID for quadratic polynomials
end % switch
fprintf(file, '    <Piece NumberOfPoints="%d" NumberOfCells="%d">\n',K*numP,K);
fprintf(file, '      <Points>\n');
fprintf(file, '        <DataArray type="Float32" NumberOfComponents="3" format="ascii">\n');
fprintf(file, '          %.12e %.12e %.1e\n',  [P1, P2, zeros(numP*K, 1)]');
fprintf(file, '        </DataArray>\n');
fprintf(file, '      </Points>\n');
fprintf(file, '      <Cells>\n');
fprintf(file, '        <DataArray type="Int32" Name="connectivity" format="ascii">\n');
fprintf(file, '           '); fprintf(file,'%d ', 0:K*numP-1);
fprintf(file, '\n        </DataArray>\n');
fprintf(file, '        <DataArray type="Int32" Name="offsets" format="ascii">\n');
fprintf(file, '           %d\n', numP:numP:numP*K);
fprintf(file, '        </DataArray>\n');
fprintf(file, '        <DataArray type="UInt8" Name="types" format="ascii">\n');
fprintf(file, '           %d\n', id*ones(K, 1));
fprintf(file, '        </DataArray>\n');
fprintf(file, '      </Cells>\n');
%% Data.
if isVec && isScalar
  fprintf(file, '      <PointData Scalars="%s" Vectors="%s">\n', varName{1}, vecNames{1});
elseif isScalar
  fprintf(file, '      <PointData Scalars="%s">\n', varName{1});
else
  fprintf(file, '      <PointData Vectors="%s">\n', vecNames{1});
end %if
for i = 1 : numel(dataLagr)
  switch N
    case 1 % locally constant
      dataLagr{i} = kron(dataLagr{i}, [1;1;1])';
    case 3 % locally linear
      dataLagr{i} = reshape(dataLagr{i}', 1, K*N);
    case 6 % locally quadratic (permutation of local edge indices due to vtk format)
      dataLagr{i} = reshape(dataLagr{i}(:, [1,2,3,6,4,5])', 1, K*N);
  end % switch
end % for
for i = 1 : length(vecNames)
  maskComp = ismember(varName, vecName.(vecNames{i}));
  numComp = sum(maskComp);
  fprintf(file, '        <DataArray type="Float32" Name="%s" NumberOfComponents="3" format="ascii">\n', vecNames{i});
  fprintf(file, '          %.9e %.9e %.9e\n', [cell2mat(reshape(dataLagr(maskComp), [], 1)).', zeros(length(dataLagr{1}), 3-numComp)]');
  fprintf(file, '        </DataArray>\n');
end % for
for i = find(~maskVec)
  fprintf(file, '        <DataArray type="Float32" Name="%s" NumberOfComponents="1" format="ascii">\n', varName{i});
  fprintf(file, '          %.9e\n', dataLagr{i});
  fprintf(file, '        </DataArray>\n');
end % for
fprintf(file, '      </PointData>\n');
%% Footer.
fprintf(file, '    </Piece>\n');
fprintf(file, '  </UnstructuredGrid>\n');
fprintf(file, '</VTKFile>\n');
%% Close file.
fclose(file);
disp(['Data written to ' fileName])
end % function
%
%> @brief Helper routine to write Tecplot-files.
function visualizeDataLagrTec(g, dataLagr, varName, fileName, tLvl)
[K, N] = size(dataLagr{1});
%% Open file.
fileName = [fileName, '.', num2str(tLvl), '.plt'];
file     = fopen(fileName, 'wt'); % if this file exists, then overwrite
%% Header.
fprintf(file, 'TITLE="FESTUNG output file"\n');
fprintf(file, ['VARIABLES=X, Y', repmat(', "%s"', 1, numel(varName)), '\n'], varName{:});
%% Points and cells.
switch N
  case {1, 3}
    P1          = reshape(g.coordV0T(:, :, 1)', 3*K, 1);
    P2          = reshape(g.coordV0T(:, :, 2)', 3*K, 1);
    numT        = K;
    V0T         = 1:length(P1);
  case 6
    P1          = reshape([g.coordV0T(:,:,1), g.baryE0T(:,[3,1,2],1)]',6*K,1);
    P2          = reshape([g.coordV0T(:,:,2), g.baryE0T(:,[3,1,2],2)]',6*K,1);
    numT        = 4*K;
    V0T         = reshape([ 1:6:6*K; 4:6:6*K; 6:6:6*K;
                            2:6:6*K; 5:6:6*K; 4:6:6*K;
                            3:6:6*K; 6:6:6*K; 5:6:6*K;
                            4:6:6*K; 5:6:6*K; 6:6:6*K ], 3, numT);
end % switch
%% Data.
for i = 1 : numel(dataLagr)
  switch N
    case 1 % locally constant
      dataLagr{i} = kron(dataLagr{i}, [1;1;1])';
    case 3 % locally linear
      dataLagr{i} = reshape(dataLagr{i}', 1, K*N);
    case 6 % locally quadratic (permutation of local edge indices due to TP format)
      dataLagr{i} = reshape(dataLagr{i}(:, [1,2,3,6,4,5])', 1, K*N);
  end % switch
end % for
%% Zone header.
fprintf(file, 'ZONE T="Time=%.3e", ', tLvl);
fprintf(file, 'N=%d, E=%d, ', length(P1), numT);
fprintf(file, 'ET=TRIANGLE, F=FEBLOCK, ');
fprintf(file, 'SOLUTIONTIME=%.3e\n\n', tLvl);
%% Point coordinates and data.
fprintf(file, '%.12e %.12e %.12e %.12e %.12e\n', P1);
fprintf(file, '\n\n');
fprintf(file, '%.12e %.12e %.12e %.12e %.12e\n', P2);
fprintf(file, '\n\n');
fprintf(file, '%.9e %.9e %.9e %.9e %.9e\n', dataLagr{:});
fprintf(file, '\n');
%% Connectivity.
fprintf(file, '%d %d %d\n', V0T);
%% Close file.
fclose(file);
disp(['Data written to ' fileName])
end % function
