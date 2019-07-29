from vmtk import vmtkscripts
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("fname", help="Enter the path to the input surface file", type=str)
args = parser.parse_args()
fname = args.fname
outputName = fname.split('.')[:-1] + ['.vtp']
outputName = ''.join(outputName)
print(outputName)
surfaceReader = vmtkscripts.vmtkSurfaceReader()
surfaceReader.InputFileName = fname
surfaceReader.Execute()

print(fname)

centerlines = vmtkscripts.vmtkCenterlines()
centerlines.Surface = surfaceReader.Surface
centerlines.AppendEndPoints = 1
centerlines.Execute()

branchExtractor = vmtkscripts.vmtkBranchExtractor()
branchExtractor.Centerlines = centerlines.Centerlines
branchExtractor.Execute()

centerlineViewer = vmtkscripts.vmtkCenterlineViewer()
centerlineViewer.Centerlines = branchExtractor.Centerlines
centerlineViewer.Execute()

surfaceWriter = vmtkscripts.vmtkSurfaceWriter()
surfaceWriter.Surface = branchExtractor.Centerlines
surfaceWriter.Mode = 'ascii'
surfaceWriter.OutputFileName = outputName
surfaceWriter.Execute()