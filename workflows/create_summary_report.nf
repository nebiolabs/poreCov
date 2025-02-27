include { summary_report; summary_report_fasta; summary_report_default } from './process/summary_report'
include { plot_coverages } from '../modules/plot_coverages.nf'
include { get_scorpio_version } from '../modules/get_scorpio_version.nf'

workflow create_summary_report_wf {
    take: 
        pangolin
        president
        nextclade
        kraken2
        alignments
        samples_table

        main:
        version_ch = Channel.fromPath(workflow.projectDir + "/configs/container.config")
        scorpio_ver_ch = get_scorpio_version()

        pangolin_results = pangolin.map {it -> it[1]}.collectFile(name: 'pangolin_results.csv', skip: 1, keepHeader: true)
        president_results = president.map {it -> it[1]}.collectFile(name: 'president_results.tsv', skip: 1, keepHeader: true)
        nextclade_results = nextclade.map {it -> it[1]}.collectFile(name: 'nextclade_results.tsv', skip: 1, keepHeader: true)
       
        alignment_files = alignments.map {it -> it[0]}.collect()
        if (params.fasta || workflow.profile.contains('test_fasta')) {
            
            summary_report_fasta(version_ch, scorpio_ver_ch, pangolin_results, president_results, nextclade_results)

        } else {
            kraken2_results = kraken2.map {it -> it[2]}.collect()
            // sort by sample name, group in lists of 6, collect the grouped plots
            coverage_plots = plot_coverages(alignments.map{it -> it[0]}.toSortedList({ a, b -> a.simpleName <=> b.simpleName }).flatten().collate(6), \
                                            alignments.map{it -> it[1]}.toSortedList({ a, b -> a.simpleName <=> b.simpleName }).flatten().collate(6)).collect()

            if (params.samples) { summary_report(version_ch, scorpio_ver_ch, pangolin_results, president_results, nextclade_results, kraken2_results, coverage_plots, samples_table) }
            else { summary_report_default(version_ch, scorpio_ver_ch, pangolin_results, president_results, nextclade_results, kraken2_results, coverage_plots) }
            
        }

        

} 
