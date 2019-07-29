from vmtk import vmtkscripts
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("fname", help="Enter the path to the input surface file", type=str)
args = parser.parse_args()
fname = args.fname
outputName = fname.split('.')[:-1] + ['.vtu']
outputName = ''.join(outputName)

surfaceReader = vmtkscripts.vmtkSurfaceReader()
surfaceReader.InputFileName = fname
surfaceReader.Execute()

surfaceRemeshing = vmtkscripts.vmtkSurfaceRemeshing()
surfaceRemeshing.Surface = surfaceReader.Surface
surfaceRemeshing.ElementSizeMode = 'edgelength'
surfaceRemeshing.TargetEdgeLength = 5.0
surfaceRemeshing.Execute()

meshGenerator = vmtkscripts.vmtkMeshGenerator()
meshGenerator.Surface = surfaceRemeshing.Surface
meshGenerator.TargetEdgeLength = 5.0
meshGenerator.Execute()

meshViewer = vmtkscripts.vmtkMeshViewer()
meshViewer.Mesh = meshGenerator.Mesh
meshViewer.Execute()

meshWriter = vmtkscripts.vmtkMeshWriter()
meshWriter.Mesh = meshGenerator.Mesh
meshWriter.Mode = 'ascii'
meshWriter.OutputFileName = outputName
meshWriter.Execute()