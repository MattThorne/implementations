# Prorank 
This is an implementation of the prorank algorithm which detect protein complexes. It uses Googles Pagerank algorithm to detect protein complexes.

## Original Paper
| Link | URL |
|------|-----|
| Research Page | https://faculty.uaeu.ac.ae/nzaki/Research.htm |
| PubMed Article | https://pubmed.ncbi.nlm.nih.gov/22685080/ |
| Artifacts | http://faculty.uaeu.ac.ae/nzaki/ProRank/ProRank-0.1.zip |

## Datasets

| File | Source |
|------|--------|
| [BIOGRID-PUBLICATION-21817-5.0.251.tab3.txt](./datasets/BIOGRID-PUBLICATION-21817-5.0.251.tab3.txt) | https://thebiogrid.org/21817/publication/proteome-survey-reveals-modularity-of-the-yeast-cell-machinery.html |
| [Fasta protein sequence](./datasets/uniprot_sprot.fasta) | https://www.uniprot.org/help/downloads |
| [CYC2008](datasets/CYC2008.txt)||

## Related Source Code
| Name | Source |
|------|--------|
| AdjustCD reference | https://academic.oup.com/bioinformatics/article/25/15/1891/211634 , https://www.comp.nus.edu.sg/~wongls/projects/complexprediction/CMC-26may09/ |
| FASTA36 | https://github.com/wrpearson/fasta36 |

## Notes
* Fasta is both a file format, and is also the name of an algorithm. Both are used in this paper.